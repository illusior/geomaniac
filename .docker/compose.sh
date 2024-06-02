#!/usr/bin/env bash

# Launch from project's root foler

. ./frontend/.docker/.scripts/contains_element.sh

# Ask user for build type
buildType=$1

buildProdType="prod"
buildPreviewType="preview"
buildDevType="dev"

buildTypeAllowed=(${buildPreviewType} ${buildDevType} ${buildProdType})

if ! contains_element "$buildType" "${buildTypeAllowed[@]}"; then
  buildType=$buildProdType
fi

composeArgs=()
if [ $buildType == $buildDevType ]; then
  composeArgs+=( "-f ./.docker/compose.override.yml" )
fi

if [ $buildType == $buildProdType ] || [ $buildType == $buildPreviewType ]; then
  composeArgs+=( "-f ./.docker/compose.traefik.yml" )
fi

composeCommand=$2

composeConfig="config"
composeUpCommand="up"
composeWatch="watch"

composeCommandAllowed=(${composeUpCommand} ${composeWatch} ${composeConfig})

if ! contains_element $composeCommand ${composeCommandAllowed[@]} ; then
  composeCommand=$composeUpCommand
fi

composeCommandArgs=()
if [ $composeCommand == $composeUpCommand ]; then
  composeCommandArgs+=( "--build" )
  composeCommandArgs+=( "--wait" )
fi

if [ $composeCommand == $composeWatch ]; then
  composeCommandArgs+=( "--no-up" )

  if [ $buildType == $buildDevType ] || [ $buildType == $buildPreviewType ]; then
    composeArgs+=( "-f ./frontend/.docker/compose.watch.$buildType.yml" )
  fi
fi

if [ $composeCommand == $composeUpCommand ]; then
  composeCommandArgs+=( "--force-recreate" )
fi

finalComand="docker compose \
    --env-file ./.docker/.${buildType}.env \
    \
    --env-file ./frontend/.docker/.${buildType}.env \
    \
    --env-file ./backend/.docker/.db.env \
    --env-file ./backend/.docker/.application.env \
    --env-file ./backend/.docker/.pgadmin.env \
    \
    -f ./.docker/compose.yml \
    \
    ${composeArgs[@]} \
    \
    ${composeCommand} \
    \
    ${composeCommandArgs[@]}"

echo "Launching this command:"
echo $finalComand
echo ""

$finalComand
