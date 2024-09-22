VERSION 0.7
IMPORT github.com/poshcode/tasks
FROM mcr.microsoft.com/dotnet/sdk:8.0
WORKDIR /work

ARG --global EARTHLY_GIT_ORIGIN_URL
ARG --global EARTHLY_BUILD_SHA
ARG --global EARTHLY_GIT_BRANCH
# These are my common paths, used in my shared /Tasks repo
ARG --global OUTPUT_ROOT=/Modules
ARG --global TEST_ROOT=/Tests
ARG --global TEMP_ROOT=/temp
# These are my common build args, used in my shared /Tasks repo
ARG --global MODULE_NAME=ErrorView
ARG --global CONFIGURATION=Release

# This works on Linux, and speeds things up dramatically because I don't need my .git folder
# But "LOCALLY" doesn't work on Windows (yet), and that's my main dev environment
# version:
#     COPY --if-exists GitVersion.yml .
#     IF [ -f ./GitVersion.yml ]
#     ELSE
#         LOCALLY
#         COPY tasks+tasks/tasks/GitVersion.yml .
#     END
#     LOCALLY
#     RUN dotnet tool update GitVersion.Tool --version 5.12.0 --global && \
#         dotnet gitversion > version.json
#     SAVE ARTIFACT ./version.json

worker:
    # Dotnet tools and scripts installed by PSGet
    ENV PATH=$HOME/.dotnet/tools:$HOME/.local/share/powershell/Scripts:$PATH
    RUN mkdir /Tasks \
        && git config --global user.email "Jaykul@HuddledMasses.org" \
        && git config --global user.name "Earthly Build"
    # I'm using Invoke-Build tasks from this other repo which rarely changes
    COPY tasks+tasks/* /Tasks
    # Dealing with dependencies first allows docker to cache packages for us
    # So the dependency cach only re-builds when you add a new dependency
    COPY RequiredModules.psd1 .
    # COPY --if-exists *.csproj .
    RUN ["pwsh", "-File", "/Tasks/_Bootstrap.ps1", "-RequiredModulesPath", "RequiredModules.psd1"]

build:
    FROM +worker
    RUN mkdir $OUTPUT_ROOT $TEST_ROOT $TEMP_ROOT
    # On Linux we could use the version: task, we wouldn't need .git/ here and
    # we could avoid re-running this every time there was a commit
    # we could copying the source and Invoke-Build script to improve caching
    COPY --if-exists --dir .git/ source/ build.psd1 Build.build.ps1 GitVersion.yml nuget.config /work
    RUN ["pwsh", "-Command", "Invoke-Build", "-Task", "Build", "-File", "Build.build.ps1"]

    # SAVE ARTIFACT [--keep-ts] [--keep-own] [--if-exists] [--force] <src> [<artifact-dest-path>] [AS LOCAL <local-path>]
    SAVE ARTIFACT $OUTPUT_ROOT/$MODULE_NAME AS LOCAL ./Modules/$MODULE_NAME

test:
    # If we run a target as a reference in FROM or COPY, it's outputs will not be produced
    # BUILD +build
    FROM +build
    # Copy the test files here, so we can avoid rebuilding when iterating on tests
    COPY --if-exists --dir Tests/ ScriptAnalyzerSettings.psd1 /work
    RUN ["pwsh", "-Command", "Invoke-Build", "-Task", "Test", "-File", "Build.build.ps1"]

    # SAVE ARTIFACT [--keep-ts] [--keep-own] [--if-exists] [--force] <src> [<artifact-dest-path>] [AS LOCAL <local-path>]
    SAVE ARTIFACT $TEST_ROOT AS LOCAL ./Modules/$MODULE_NAME-TestResults

# pack:
#     BUILD +test # So that we get the module artifact from build too
#     FROM +test
#     RUN ["pwsh", "-Command", "Invoke-Build", "-Task", "Pack", "-File", "Build.build.ps1", "-Verbose"]
#     SAVE ARTIFACT $OUTPUT_ROOT/publish/*.nupkg AS LOCAL ./Modules/$MODULE_NAME-Packages/

push:
    FROM +build
    RUN --push --secret NUGET_API_KEY --secret PSGALLERY_API_KEY -- \
        pwsh -Command Invoke-Build -Task Push -File Build.build.ps1 -Verbose

all:
    # BUILD +build
    BUILD +test
    BUILD +push
