# Slack Emoji Migrate

## About

This Docker app automates the process of migrating custom emoji from Slack to Mattermost.

## Setup & Configuration

### 1. Get a Slack API Token

1. From your Workspace, go to Settings & Administration > Manage Apps
2. Click `Build` in the top right
3. Click `Create New App` > From Scratch
4. Name the app and grant it access to a workspace
5. Click "Permissions" and it takes you to "Scopes"
6. Under Bot Token Scopes, click `Add an OAuth Scope`
7. Select the `emoji:read` scope
8. Scroll to the top and click "Install into Workspace"
9. Click "Allow"
10. Copy the `Bot User OAuth Token`

### 2. Generate a Mattermost Auth Token

Either create a bot account with admin permissions, or create a personal access token. Make sure that Custom Emoji are enabled in the System Console and that the account has permission to create custom emoji

### 3. Set Environment Variables

#### Method 1: A `.env` File

Create a file in this directory with these contents:

```
SLACK_API_TOKEN=<Slack API token>
MATTERMOST_URL=<Your Mattermost URL>
MATTERMOST_TOKEN=<Your Mattermost Authentication Token>
```

Replace the values

#### Method 2: Modify the `docker-compose` file 

Edit the `docker-compose.yml` file replace the environment variables with your settings, e.g.

```yaml
version: "3.7"

services:
  slack-emoji-migrate:
    build: .
    volumes:
      - ./output:/usr/src/app/output
    environment:
      - SLACK_API_TOKEN=xoxb-abc1234.....
      - MATTERMOST_URL=https://mattermost.example.com/
      - MATTERMOST_TOKEN=ncdfitoh9inixpbycp81f1zkia
```

### 4. Run the script

```bash
docker-compose up
```

### 4. Clean Up

Once the script has been run successfully, delete the image with this command:

```bash
docker image rm slack-emoji-migrate_slack-emoji-migrate
```