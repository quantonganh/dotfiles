#!/bin/bash

# https://developer.apple.com/library/archive/technotes/tn2450/_index.html
hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0},{"HIDKeyboardModifierMappingSrc":0x7000000E6,"HIDKeyboardModifierMappingDst":0x7000000E4}]}'
