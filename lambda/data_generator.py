import json
import random
import logging
import os
from datetime import datetime, timedelta
from dotenv import load_dotenv

import boto3
from faker import Faker

load_dotenv()

logger = logging.getLogger()
logger.setLevel(logging.INFO)

RAW_BUCKET_NAME = os.getenv('RAW_BUCKET_NAME')


def generate_game_info(num_games: int, fake: Faker) -> list[dict[str]]:
    """
    Function to generate games info.

    Args:
        num_games (int): Number of games for which the function generates the info.
        fake (Faker): Faker object.

    Returns:
        game_info (list[dict[str]]): List of games.
    """
    publishers = [
        'Electronic Arts',
        'Activision',
        'Ubisoft',
        'Nintendo',
        'Sony Interactive Entertainment',
        'Microsoft Studios',
        'Take-Two Interactive',
        'Rockstar Games',
        'Square Enix',
        'Capcom',
        'Sega',
        'Bethesda Softworks',
        'Bandai Namco Entertainment',
        'Konami',
        '2K Games',
    ]

    game_info = []
    for _ in range(num_games):
        game = {
            'GameID': fake.uuid4(),
            'Publisher': random.choice(publishers),
            'Rating': random.choice(['E', 'T', 'M']),
            'Genre': random.choice(['MMO', 'FPS', 'RPG', 'Adventure', 'Strategy']),
            'Release': fake.date_between(
                start_date='-10y', end_date='today'
            ).isoformat(),
        }
        game_info.append(game)

    return game_info


def generate_player_info(
    num_players: int, games_ids: list[str], fake: Faker
) -> list[dict[str | int]]:
    """
    Function to generate players info.

    Args:
        games_ids (list[str]): List of games ids. Each player gets random game id.
        fake (Faker): Faker object.

    Returns:
        player_activity (list[dict[str | int]]): List of players.
    """
    player_activity = []
    for _ in range(num_players):
        start_time = fake.date_time_this_month()
        end_time = start_time + timedelta(minutes=random.randint(30, 300))
        activity = {
            'PlayerID': fake.uuid4(),
            'GameID': random.choice(games_ids),
            'SessionID': fake.uuid4(),
            'StartTime': start_time.isoformat(),
            'EndTime': end_time.isoformat(),
            'ActivityType': random.choice(['Playing', 'AFK', 'In-Queue']),
            "Level": random.randint(1, 100),
            "ExperiencePoints": float(random.randint(100, 10000)),
            "AchievementsUnlocked": random.randint(0, 10),
            "CurrencyEarned": float(random.randint(100, 5000)),
            "CurrencySpent": float(random.randint(0, 3000)),
            "QuestsCompleted": random.randint(0, 20),
            "EnemiesDefeated": random.randint(0, 50),
            "ItemsCollected": random.randint(0, 100),
            "Deaths": random.randint(0, 10),
            "DistanceTraveled": float(random.randint(1, 10000)),
            "ChatMessagesSent": random.randint(0, 100),
            "TeamEventsParticipated": random.randint(0, 5),
            "SkillLevelUp": random.randint(0, 10),
            "PlayMode": random.choice(['Solo', 'Co-op', 'PvP']),
        }
        player_activity.append(activity)

    return player_activity


def put_object(bucket_name: str, object_key: str, data: list):
    """
    Function to put object to the S3 bucket.

    Args:
        bucket_name (str): S3 bucket for raw data.
        object_key (str): S3 object key.
        data (list): Game info or player activity list.
    """
    data_string = json.dumps(data, indent=2)

    s3 = boto3.client('s3')
    try:
        s3.put_object(Bucket=bucket_name, Key=object_key, Body=data_string)
        logger.info(
            f'Successfully put object to the bucket: {bucket_name} with key: {object_key}\n'
        )
    except Exception as e:
        logger.error(
            f'Failed to put object to the bucket: {bucket_name} with key: {object_key}: {e}\n'
        )


def lambda_handler(event, context):
    """
    Function to handle data generation events.

    Args:
        event (dict): Lambda event.
        context (LambdaContext): Lambda context.
    """
    logger.info(f"Received event: {event}\n")

    num_games = 10
    num_players = 10000

    fake = Faker()

    # Generate fake lists for games info and players activity
    games = generate_game_info(num_games=num_games, fake=fake)
    games_ids = [game['GameID'] for game in games]
    players = generate_player_info(
        num_players=num_players, games_ids=games_ids, fake=fake
    )

    bucket_name = RAW_BUCKET_NAME
    games_key = f'Games/{datetime.now().strftime("%Y-%m-%d")}/games_info_{datetime.now().strftime("%Y-%m-%d")}.json'
    players_key = f'Players/{datetime.now().strftime("%Y-%m-%d")}/players_info_{datetime.now().strftime("%Y-%m-%d")}.json'

    # Put games info and players activity to the S3 bucket
    put_object(bucket_name=bucket_name, object_key=games_key, data=games)
    put_object(bucket_name=bucket_name, object_key=players_key, data=players)
