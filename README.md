# ghactions

* ![Build Status](https://github.com/snw35/ghrunner/actions/workflows/update.yml/badge.svg)
* [Dockerhub: snw35/ghrunner](https://hub.docker.com/r/snw35/ghrunner)

Github Actions runner container for self-hosted runners.

This container can be used to set up a self-hosted Github Actions runner, e.g an instance that will accept Github Actions jobs and run them on your own hardware.

## How to Use

### Create Access Token

First, you will need a fine-grained access token with enough permissions to allow self-hosted runners to register.

In Github, navigate to:
 * Settings
   * Developer Settings
     * Personal access tokens
       * Fine-grained tokens
         * Generate new token

Give the token a meaningful name and description, and (recommended) set the expiration date to a year ahead.
Choose "Only select repositories" and select the repo you want to configure a self-hosted runner for.
Click "Add permissions" and select "Administration", then change "Access: Read-only" to "Read and write".

Create the token and note it somewhere secure (password manager recommended).

### Edit docker-compose.yaml

Clone the repo:

```
git clone https://github.com/snw35/ghrunner
```

Edit the docker-compose file and set the following variables:

 * `REPOSITORY` - Set to the Github repository you want to configure the runner for. The runner will only accept jobs from this repo. The format must be `owner/repo`, e.g `snw35/ghrunner`.
 * `ACCESS_TOKEN` - Set to the fine-grained access token that you have created above.
 * `RUNNER_NAME` - You can choose the name your runner will have, or leave it at the default of 'selfhosted'.

### Start Runner

Bring the compose project up:

```
docker compose up -d && docker compose logs -f
```

You should see the runner successfully register if your token and settings are correct:

```
ghrunner  | √ Connected to GitHub
ghrunner  |
ghrunner  | Current runner version: '2.331.0'
ghrunner  | 2026-01-23 11:16:39Z: Listening for Jobs
```

Under your repo on Github, you can navigate to "Actions" -> "Runners" -> "Self-hosted runners" to view your self-hosted runners. You should see the runner appear with the name you gave it, or 'selfhosted' by default.

Every time you restart the runner, it will re-use this name, so you won't accumulate stale entries. If you want to remove this runner entry, see https://github.com/beikeni/delete-github-runners
