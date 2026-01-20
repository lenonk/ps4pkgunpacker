#pragma once

#include <iostream>
#include <string_view>
#include <format>

namespace Common::Log {
enum class Level { Trace, Debug, Info, Warning, Error, Critical };
enum class Class { Log, Common, Core, Crypto, FileFormat, Frontend, Common_Filesystem };

template <typename... Args>
inline void LogMessage(Level level, Class cls, const char* format, Args&&... args) {
    std::cerr << "[" << static_cast<int>(level) << "][" << static_cast<int>(cls) << "] "
              << std::vformat(format, std::make_format_args(args...)) << std::endl;
}
}

#define LOG_INFO(cls, ...) Common::Log::LogMessage(Common::Log::Level::Info, Common::Log::Class::cls, __VA_ARGS__)
#define LOG_ERROR(cls, ...) Common::Log::LogMessage(Common::Log::Level::Error, Common::Log::Class::cls, __VA_ARGS__)
#define LOG_WARNING(cls, ...) Common::Log::LogMessage(Common::Log::Level::Warning, Common::Log::Class::cls, __VA_ARGS__)
#define LOG_DEBUG(cls, ...) Common::Log::LogMessage(Common::Log::Level::Debug, Common::Log::Class::cls, __VA_ARGS__)
#define LOG_CRITICAL(cls, ...) Common::Log::LogMessage(Common::Log::Level::Critical, Common::Log::Class::cls, __VA_ARGS__)
