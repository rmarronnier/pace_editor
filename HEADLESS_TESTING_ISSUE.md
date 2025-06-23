# Headless Testing Issue Report

## Problem

The current "headless" specs are not truly headless - they still open a graphics window because:

1. **Dependency Chain**: 
   - Specs require `spec_helper.cr`
   - `spec_helper.cr` requires `../src/pace_editor`
   - `pace_editor.cr` requires `point_click_engine`
   - `point_click_engine` initializes Raylib immediately on load

2. **UI Component Dependencies**:
   - UI components like `ScriptEditor` and `AnimationEditor` depend on Raylib types
   - Even testing their logic requires loading the full Raylib library

## Current State

When running any spec that includes the main application code, Raylib initializes and opens a window with:
```
INFO: Initializing raylib 5.5
INFO: DISPLAY: Device initialized successfully
```

## Solutions

### 1. Short-term Solution (Implemented)
Created `spec/truly_headless_spec.cr` that doesn't load any application code and runs without graphics.

### 2. Proper Solution (Recommended)
To make UI components truly testable without graphics:

1. **Extract Interfaces**: Create interfaces/protocols for Raylib dependencies
2. **Dependency Injection**: Allow UI components to accept mock implementations
3. **Separate Logic from Drawing**: Move business logic to separate classes that don't depend on Raylib

### 3. Alternative Approaches

#### a) Conditional Compilation
```crystal
{% if env("HEADLESS_SPECS") == "true" %}
  # Load mock Raylib
{% else %}
  require "raylib-cr"
{% end %}
```

#### b) Abstract Graphics Layer
Create an abstraction layer between UI components and Raylib, allowing for mock implementations during testing.

## Impact

Currently, all UI specs require a graphics environment, making them unsuitable for:
- CI/CD pipelines
- Headless servers
- Automated testing environments

## Recommendation

For now, focus testing efforts on:
1. Core logic that doesn't require UI
2. Model and data structure tests
3. Validation and export functionality

UI components should be tested through:
1. Manual testing during development
2. Integration tests with graphics available
3. Future refactoring to enable true headless testing