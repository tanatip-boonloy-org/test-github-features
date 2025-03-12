#!/usr/bin/env bash

################################################################################
# 1) verify that required environment variables are set
################################################################################
if [ -z "$COMMITS" ]; then
    echo "ERROR: The environment variable COMMITS is not set or is empty."
    exit 1
fi

if [ -z "$DELIMITER" ]; then
    DELIMITER="|||"
fi

if [ -z "$VERSION" ]; then
    echo "ERROR: The environment variable VERSION is not set or is empty."
    exit 1
fi
################################################################################
# 2) Prepare variables
################################################################################
CHANGELOG_FILE="CHANGELOG.md"
NEW_CONTENT="# CHANGELOG\n\n## [${VERSION}]\n\n"

FEATURES=""
FIXES=""
DOCS=""
TESTS=""
CHORES=""
REFACTORS=""
PERF=""
STYLES=""
BREAKING=""
OTHER=""

################################################################################
# 3) Process commits
################################################################################
IFS=$DELIMITER read -ra DELIMITED_COMMITS <<< "$COMMITS"
for COMMIT in "${DELIMITED_COMMITS[@]}"; do
    # Skip empty lines
    [ -z "$COMMIT" ] && continue

    # Remove any leading/trailing quotes
    COMMIT="$(echo "$COMMIT" | sed 's/^"//; s/"$//')"

    # Skip merge commits
    if [[ "$COMMIT" =~ ^Merge[[:space:]] ]]; then
        continue
    fi

    if [[ $COMMIT =~ ^([a-zA-Z]+)(\([a-zA-Z0-9_-]+\))?!?:\ (.+)$ ]]; then
        TYPE="${BASH_REMATCH[1]}"
        SCOPE="${BASH_REMATCH[2]}"
        MESSAGE="${BASH_REMATCH[3]}"
        
        # Clean up parentheses around scope
        SCOPE="${SCOPE//[()]/}"

        # Format final line
        if [ -n "$SCOPE" ]; then
            FORMATTED="- **${SCOPE}:** ${MESSAGE}"
        else
            FORMATTED="- ${MESSAGE}"
        fi
        
        # Check for breaking change (exclamation before colon)
        if [[ $COMMIT =~ ^[a-zA-Z]+(\([a-zA-Z0-9_-]+\))?!: ]]; then
            BREAKING+="${FORMATTED}\n"
            continue
        fi

        # Categorize by type
        case "$TYPE" in
            feat|feature)       FEATURES+="${FORMATTED}\n" ;;
            fix|bugfix)         FIXES+="${FORMATTED}\n"    ;;
            docs|documentation) DOCS+="${FORMATTED}\n"     ;;
            test|tests)         TESTS+="${FORMATTED}\n"    ;;
            chore|build|ci)     CHORES+="${FORMATTED}\n"   ;;
            refactor)           REFACTORS+="${FORMATTED}\n";;
            perf|performance)   PERF+="${FORMATTED}\n"     ;;
            style)              STYLES+="${FORMATTED}\n"   ;;
            *)                  OTHER+="${FORMATTED}\n"    ;;
        esac
    else
        # Non-conventional commit: just place in OTHER
        FORMATTED="- ${COMMIT}"
        OTHER+="${FORMATTED}\n"
    fi
done

################################################################################
# 4) Helper function to append sections only if they have content
################################################################################
append_section() {
    local title="$1"
    local content="$2"
    [ -n "$content" ] && NEW_CONTENT+=$'### '"${title}"$'\n'"${content}"$'\n'
}

# Append each section
append_section "⚠️ BREAKING CHANGES"       "$BREAKING"
append_section "✨ Features"               "$FEATURES"
append_section "🐛 Fixes"                  "$FIXES"
append_section "⚡ Performance Improvements" "$PERF"
append_section "♻️ Refactors"              "$REFACTORS"
append_section "📝 Documentation"          "$DOCS"
append_section "💄 Styles"                 "$STYLES"
append_section "✅ Tests"                  "$TESTS"
append_section "🔧 Chores"                 "$CHORES"
append_section "🔄 Other Changes"          "$OTHER"

################################################################################
# 5) Capture any existing versions from the CHANGELOG
################################################################################
EXISTING_VERSIONS=""
if [ -f "$CHANGELOG_FILE" ]; then
    # Extract all content after the FIRST version header in existing CHANGELOG
    # This way we preserve older versions.
    EXISTING_VERSIONS=$(awk '/^## \[/{found=1} found' "$CHANGELOG_FILE")
fi

################################################################################
# 6) Merge new content with old
################################################################################
FINAL_CONTENT="${NEW_CONTENT}"
[ -n "$EXISTING_VERSIONS" ] && FINAL_CONTENT+="${EXISTING_VERSIONS}"

echo -e "$FINAL_CONTENT" > "$CHANGELOG_FILE"
echo "CHANGELOG.md has been updated with version $VERSION"
