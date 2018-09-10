#!/usr/bin/env bash

function capitalize() {
  local outRes=$(echo ${1} | awk '{ for ( i=1; i <= NF; i++) {   sub(".", substr(toupper($i),1,1) , $i)  } print }')
  echo "${outRes}"
}

gradlePath="${PWD}/gradlew"
flavor=""
artifactSuffix=""
artifactSuffixPom=""

rootProjectName=$(${gradlePath} projects | grep "Root project '" | awk -F "'" '{print $2}')
artifactName=${rootProjectName}
artifactGroup=""
artifactVersion=""
moduleName=""
tasks="0"
publishType="local"
verbosity=""
additionalArgs=""

function clean() {
    ./gradlew :clean
}

function usage() {
    echo "Minter local maven publishing script"
    echo ""
    echo "./publish.sh"
    echo "    -h --help         Print this help"
    echo "    -p --project      Sub project (module) name (current: ${rootProjectName})"
    echo "       --list-flavors Print flavors list"
    echo "       --tasks        Print gradle tasks with given config"
    echo "    -f --flavor       Choose flavor name by \"--list-flavors\""
    echo "    -s --suffix       Artifact suffix"
    echo "    -n --name         Artifact name (using instead of project.name)"
    echo "    -g --group        Artifact group"
    echo "       --version      Artifact version"
    echo "       --clean        Clean build"
    echo "    -t --type         Publish type. Default: \"local\". Variants: \"local\", \"bintray\""
    echo "       --args         Additional gradlew args. Must be quoted"
    echo "    -v --verbosity    Gradle verbosity: info, debug, stacktrace etc"
    echo ""
}

function printFlavors() {
    ./gradlew printFlavors
}

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    usage
    exit
    ;;
    --list-flavors)
    printFlavors
    exit
    ;;
    --tasks)
    tasks="1"
    shift # past argument
    shift # past value
    ;;
    --clean)
    clean
    exit
    ;;
    -s|--suffix)
    artifactSuffix="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--project)
    moduleName=":$2"
    shift # past argument
    shift # past value
    ;;
    -n|--name)
    artifactName="$2"
    shift # past argument
    shift # past value
    ;;
    -g|--group)
    artifactGroup="$2"
    shift # past argument
    shift # past value
    ;;
    --version)
    artifactVersion="$2"
    shift # past argument
    shift # past value
    ;;
    -f|--flavor)
    flavor="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--type)
    publishType="$2"
    shift # past argument
    shift # past value
    ;;
    -v|--verbosity)
    verbosity="$2"
    shift # past argument
    shift # past value
    ;;
    --args)
    additionalArgs="$2"
    shift # past argument
    shift # past value
    ;;
    *)
          # unknown option
          echo "Unknown option ${key} ${2}"
          exit 1
    ;;
esac
done

flavorCap=$(capitalize ${flavor})
projectNameCap=$(capitalize ${rootProjectName})


if [ "${artifactSuffix}" != "" ]
then
    artifactSuffixPom="-${artifactSuffix}"
fi

if [ "${flavor}" == "" ]
then
    echo "Flavor can't be empty"
    exit 1
fi

if [ "${moduleName}" == "${rootProjectName}" ]
then
    moduleName=""
fi

if [ "${tasks}" == "1" ]
then
    ${gradlePath} \
    -PbuildFlavor=${flavor} \
    -PartifactSuffix=${artifactSuffix} \
    -PbuildArtifactName=${artifactName} \
    ${moduleName}:tasks
    exit 0
fi

if [ "${verbosity}" != "" ]
then
    verbosity="--${verbosity}"
fi

publishTypeInternal=""
publishTypeAdditions=""
case "${publishType}" in
    local)
        publishTypeInternal="publishToMavenLocal"
        publishTypeAdditions=""
        ;;
    bintray)
        publishTypeInternal="bintrayUpload"
        publishTypeAdditions="${moduleName}:bintrayPublish"
        ;;
    *)
        echo "Unknown publish type: ${publishType}"
        exit 1
        ;;
esac

echo "Running commands in module: ${moduleName}"

${gradlePath} \
    -PbuildFlavor=${flavor} \
    -PartifactSuffix=${artifactSuffix} \
    -PbuildArtifactName=${artifactName} \
    -PbuildArtifactGroup="${artifactGroup}" \
    -PbuildArtifactVersion="${artifactVersion}" \
    ${moduleName}:assemble${flavorCap} \
    ${moduleName}:androidSources \
    ${moduleName}:androidJavadoc \
    ${moduleName}:androidJavadocJar \
    ${moduleName}:generatePomFileFor${projectNameCap}${artifactSuffixPom}Publication \
    ${moduleName}:${publishTypeInternal} ${publishTypeAdditions} ${verbosity} ${additionalArgs}