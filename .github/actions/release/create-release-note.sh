#!/bin/bash

# Check if both arguments are provided
if [ $# -ne $COMMITS ]; then
    echo "env: COMMITS not found."
    exit 1
fi
if [ $# -ne $VERSION ]; then
    echo "env: VERSION not found."
    exit 1
fi

# Create output file
OUTPUT_FILE="release-note.md"

# Write header to file
echo "# Release v${VERSION}" > $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Initialize categories
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

# Process each commit message
echo "$COMMITS" | while IFS= read -r COMMIT; do
    # Skip empty lines
    if [ -z "$COMMIT" ]; then
        continue
    fi

    # Clean up the message - remove quotes if present
    COMMIT=$(echo "$COMMIT" | sed 's/^"//;s/"$//')

    # Try to parse conventional commit format: type(scope): message
    if [[ $COMMIT =~ ^([a-zA-Z]+)(\([a-zA-Z0-9_-]+\))?!?:\ (.+)$ ]]; then
        TYPE="${BASH_REMATCH[1]}"
        SCOPE="${BASH_REMATCH[2]}"
        MESSAGE="${BASH_REMATCH[3]}"
        
        # Clean up scope
        SCOPE="${SCOPE//[()]/}"
        
        # Format the message
        if [ -n "$SCOPE" ]; then
            FORMATTED="- **${SCOPE}:** ${MESSAGE}"
        else
            FORMATTED="- ${MESSAGE}"
        fi
        
        # Check for breaking changes
        if [[ $COMMIT =~ ^[a-zA-Z]+(\([a-zA-Z0-9_-]+\))?!: ]]; then
            BREAKING="${BREAKING}${FORMATTED}\n"
            continue
        fi
        
        # Categorize by type
        case $TYPE in
            feat|feature)
                FEATURES="${FEATURES}${FORMATTED}\n"
                ;;
            fix|bugfix)
                FIXES="${FIXES}${FORMATTED}\n"
                ;;
            docs|documentation)
                DOCS="${DOCS}${FORMATTED}\n"
                ;;
            test|tests)
                TESTS="${TESTS}${FORMATTED}\n"
                ;;
            chore|build|ci)
                CHORES="${CHORES}${FORMATTED}\n"
                ;;
            refactor)
                REFACTORS="${REFACTORS}${FORMATTED}\n"
                ;;
            perf|performance)
                PERF="${PERF}${FORMATTED}\n"
                ;;
            style)
                STYLES="${STYLES}${FORMATTED}\n"
                ;;
            *)
                OTHER="${OTHER}${FORMATTED}\n"
                ;;
        esac
    else
        # For non-conventional commits, just add as-is with some cleanup
        FORMATTED="- ${COMMIT}"
        OTHER="${OTHER}${FORMATTED}\n"
    fi
done

# Write sections to file if they have content
if [ -n "$BREAKING" ]; then
    echo "## ⚠️ BREAKING CHANGES" >> $OUTPUT_FILE
    echo -e "$BREAKING" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
fi

if [ -n "$FEATURES" ]; then
    echo "## ✨ Features" >> $OUTPUT_FILE
    echo -e "$FEATURES" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
fi

if [ -n "$FIXES" ]; then
    echo "## 🐛 Fixes" >> $OUTPUT_FILE
    echo -e "$FIXES" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
fi

if [ -n "$PERF" ]; then
    echo "## ⚡ Performance Improvements" >> $OUTPUT_FILE
    echo -e "$PERF" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
fi

if [ -n "$REFACTORS" ]; then
    echo "## ♻️ Refactors" >> $OUTPUT_FILE
    echo -e "$REFACTORS" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
fi

if [ -n "$DOCS" ]; then
    echo "## 📝 Documentation" >> $OUTPUT_FILE
    echo -e "$DOCS" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
fi

if [ -n "$STYLES" ]; then
    echo "## 💄 Styles" >> $OUTPUT_FILE
    echo -e "$STYLES" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
fi

if [ -n "$TESTS" ]; then
    echo "## ✅ Tests" >> $OUTPUT_FILE
    echo -e "$TESTS" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
fi

if [ -n "$CHORES" ]; then
    echo "## 🔧 Chores" >> $OUTPUT_FILE
    echo -e "$CHORES" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
fi

if [ -n "$OTHER" ]; then
    echo "## 🔄 Other Changes" >> $OUTPUT_FILE
    echo -e "$OTHER" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
fi

echo "Release note created at: $OUTPUT_FILE"