task :validate_version do
    eval(`arc paste P142`)
end

task :clean do
    sh("rm -rf #{DERIVED_DATA_DIR}/*")
end

task :bootstrap do
    sh('carthage checkout')
    sh("carthage build #{CARTHAGE_BUILD_FLAGS} | #{PRETTIFY}")
end

task :test do
    sh("#{BUILD_TOOL} test #{BUILD_FLAGS_TEST} | #{PRETTIFY}")
end

task :archive do
    sh("carthage build #{CARTHAGE_ARCHIVE_FLAGS} | #{PRETTIFY}")
    sh("carthage archive #{LIBRARY_NAME} --output #{ARCHIVE_PATH}")
end

task :increment_version do
    eval(`arc paste P142`)
end

task :upload_archive do
    ENV['GITHUB_REPO'] = "Automatic/#{LIBRARY_NAME}"
    ENV['ARCHIVE_PATH'] = ARCHIVE_PATH

    eval(`arc paste P148`)
end

task :diff => [
    :validate_version,
    :clean,
    :bootstrap,
    :test,
    :archive
]

task :ci => [
    :clean,
    :bootstrap,
    :test,
    :archive,
    :increment_version,
    :upload_archive
]

private

# Xcodebuild

LIBRARY_NAME = 'AUTUserNotifications'
TEST_SDK = 'iphonesimulator'
DERIVED_DATA_DIR = "#{ENV['HOME']}/Library/Developer/Xcode/DerivedData"

BUILD_TOOL = 'xcodebuild'

BUILD_FLAGS_TEST =
    "-scheme #{LIBRARY_NAME} "\
    "-sdk #{TEST_SDK}"

PRETTIFY = "xcpretty; exit ${PIPESTATUS[0]}"

# Carthage

CARTHAGE_BUILD_FLAGS =
    "--platform iOS "\
    "--verbose"

CARTHAGE_ARCHIVE_FLAGS =
    "--no-skip-current " +
    CARTHAGE_BUILD_FLAGS

PRODUCT_NAME = "#{LIBRARY_NAME}.framework"
PRODUCT_PATH = "Carthage/Build/iOS/#{PRODUCT_NAME}"
ARCHIVE_PATH = "#{PRODUCT_NAME}.zip"
