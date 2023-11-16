#!/usr/bin/env bash

# check for necessary env vars
[ "${DOMAIN}" = '' ] && echo "❌ 'DOMAIN' env var not set" && exit 1
[ "${GITHUB_REPO_REF}" = '' ] && echo "❌ 'GITHUB_REPO_REF' env var not set" && exit 1
[ "${GITHUB_SHA}" = '' ] && echo "❌ 'GITHUB_SHA' env var not set" && exit 1
[ "${GITHUB_BRANCH}" = '' ] && echo "❌ 'GITHUB_BRANCH' env var not set" && exit 1

[ "${DOCKER_PASSWORD}" = '' ] && echo "❌ 'DOCKER_PASSWORD' env var not set" && exit 1
[ "${DOCKER_USER}" = '' ] && echo "❌ 'DOCKER_USER' env var not set" && exit 1
[ "${CYAN_TOKEN}" = '' ] && echo "❌ 'CYAN_TOKEN' env var not set" && exit 1
[ "${CYAN_PATH}" = '' ] && echo "❌ 'CYAN_PATH' env var not set" && exit 1

set -eou pipefail

onExit() {
  rc="$?"
  if [ "$rc" = '0' ]; then
    echo "✅ Successfully built and run images"
  else
    echo "❌ Failed to run Docker image"
  fi
}

trap onExit EXIT

# Login to GitHub Registry
echo "🔐 Logging into docker registry..."
echo "${DOCKER_PASSWORD}" | docker login "${DOMAIN}" -u "${DOCKER_USER}" --password-stdin
echo "✅ Successfully logged into docker registry!"

echo "📝 Generating Image tags..."

# obtaining the version
SHA="$(echo "${GITHUB_SHA}" | head -c 6)"
BRANCH="${GITHUB_BRANCH//[._-]*$//}"
IMAGE_VERSION="${SHA}-${BRANCH}"

# Obtain image
BLOB_IMAGE_ID="${DOMAIN}/${GITHUB_REPO_REF}/template-blob"
BLOB_IMAGE_ID=$(echo "${BLOB_IMAGE_ID}" | tr '[:upper:]' '[:lower:]') # convert to lower case
# Generate image references
BLOB_COMMIT_IMAGE_REF="${BLOB_IMAGE_ID}:${IMAGE_VERSION}"

TEMPLATE_IMAGE_ID="${DOMAIN}/${GITHUB_REPO_REF}/template-script"
TEMPLATE_IMAGE_ID=$(echo "${TEMPLATE_IMAGE_ID}" | tr '[:upper:]' '[:lower:]') # convert to lower case
# Generate image references
TEMPLATE_COMMIT_IMAGE_REF="${TEMPLATE_IMAGE_ID}:${IMAGE_VERSION}"

# Generate cache references
echo "  ✅ Blob Commit Image Ref: ${BLOB_COMMIT_IMAGE_REF}"
echo "  ✅ Template Commit Image Ref: ${TEMPLATE_COMMIT_IMAGE_REF}"

echo "🔨 Building Blob Dockerfile..."
# build blob image
docker buildx build \
  "." \
  -f "${CYAN_PATH}/blob.Dockerfile" \
  --platform="linux/arm64,linux/amd64" \
  --push \
  -t "${BLOB_COMMIT_IMAGE_REF}"

echo "✅ Pushed blob image!"

echo "🔨 Building Template Dockerfile..."
# build blob image
docker buildx build \
  "./${CYAN_PATH}" \
  -f "${CYAN_PATH}/Dockerfile" \
  --platform="linux/arm64,linux/amd64" \
  --push \
  -t "${TEMPLATE_COMMIT_IMAGE_REF}"
echo "✅ Pushed template image!"

echo "🔨 Pushing to Cyanprint..."
cyanprint push template "${BLOB_IMAGE_ID}" "${IMAGE_VERSION}" "${TEMPLATE_IMAGE_ID}" "${IMAGE_VERSION}"
echo "✅ Pushed to Cyanprint!"
