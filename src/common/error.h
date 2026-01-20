// SPDX-FileCopyrightText: 2013 Dolphin Emulator Project
// SPDX-FileCopyrightText: 2014 Citra Emulator Project
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <string>

#include <iostream>

// Only define these if not already defined by assert.h
#ifndef UNREACHABLE
#define UNREACHABLE() std::abort()
#endif

#ifndef UNREACHABLE_MSG
#define UNREACHABLE_MSG(msg, ...) do { std::cerr << "Unreachable code hit: " << msg << std::endl; std::abort(); } while (false)
#endif

#ifndef ASSERT
#define ASSERT(cond) do { if (!(cond)) { std::cerr << "Assertion failed: " << #cond << std::endl; std::abort(); } } while (false)
#endif

#ifndef ASSERT_MSG
#define ASSERT_MSG(cond, msg, ...) do { if (!(cond)) { std::cerr << "Assertion failed: " << msg << std::endl; std::abort(); } } while (false)
#endif

namespace Common {

// Generic function to get last error message.
// Call directly after the command or use the error num.
// This function might change the error code.
// Defined in error.cpp.
[[nodiscard]] std::string GetLastErrorMsg();

// Like GetLastErrorMsg(), but passing an explicit error code.
// Defined in error.cpp.
[[nodiscard]] std::string NativeErrorToString(int e);

} // namespace Common
