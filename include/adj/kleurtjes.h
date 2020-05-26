// This library requires c++11
// Made by:
//      Aron de Jong (s2120437)
// Using ideas/code snippets from
//   https://github.com/agauniyal/rang/blob/master/include/rang.hpp
//
// This external library is made for easy printing of ansi codes
//
// Created on:
// 		2020-02-10
// Last edit:
//      2020-02-10
//
#pragma once

#if defined(__unix__) || defined(__unix) || defined(__linux__)
#define OS_LINUX
#elif defined(WIN32) || defined(_WIN32) || defined(_WIN64)
#define OS_WIN
#elif defined(__APPLE__) || defined(__MACH__)
#define OS_MAC
#else
#error Unknown Platform
#endif

#ifdef OS_LINUX
#include <unistd.h>
#endif

#include <algorithm>
#include <cstring>
#include <atomic>

namespace adj {

enum class style : uint8_t
{
	reset     = 0,
	bold      = 1,
	dim       = 2,
	italic    = 3,
	underline = 4,
	blink     = 5,
	rblink    = 6,
	reversed  = 7,
	conceal   = 8,
	crossed   = 9
};

enum class fg : uint8_t
{
	black   = 30,
	red     = 31,
	green   = 32,
	yellow  = 33,
	blue    = 34,
	magenta = 35,
	cyan    = 36,
	gray    = 37,
	reset   = 39,

	bblack   = 90,
	bred     = 91,
	bgreen   = 92,
	byellow  = 93,
	bblue    = 94,
	bmagenta = 95,
	bcyan    = 96,
	bgray    = 97
};

enum class bg : uint8_t
{
	black   = 40,
	red     = 41,
	green   = 42,
	yellow  = 43,
	blue    = 44,
	cyan    = 46,
	gray    = 47,
	reset   = 49,

	bblack   = 100,
	bred     = 101,
	bgreen   = 102,
	byellow  = 103,
	bblue    = 104,
	bmagenta = 105,
	bcyan    = 106,
	bgray    = 107
};

enum class control : uint8_t
{
	Off,
	Auto,
	Force
};


namespace implementation
{

inline std::atomic<control>
&ansiMode() noexcept
{
	static std::atomic<control> value(control::Auto);
	return value;
}

inline bool
supportsColor() noexcept
{
#if defined(OS_LINUX) || defined(OS_MAC)
	static const bool result = 
	[] {
		const char *Terms[] =
		{
			"ansi",
			"color",
			"console",
			"cygwin",
			"gnome",
			"konsole",
			"kterm",
			"linux",
			"msys",
			"putty",
			"rxvt",
			"screen",
			"vt100",
			"xterm",
			"alacritty",
		};
		const char *env_p = std::getenv("TERM");
		if (env_p == nullptr)
			return false;

		return std::any_of(std::begin(Terms), std::end(Terms),
		                   [&](const char *term)
		                   {
		                     return std::strstr(env_p, term) != nullptr;
		                   });
	}();
#elif defined(OS_WIN)
	static constexpr bool result = false;
#endif
	return result;
}

inline bool
isTerminal(const std::streambuf *osbuf) noexcept
{
	using std::cerr;
	using std::clog;
	using std::cout;
#if defined(OS_LINUX) || defined(OS_MAC)
	if (osbuf == cout.rdbuf()) {
		static const bool cout_term = isatty(fileno(stdout)) != 0;
		return cout_term;
	} else if (osbuf == clog.rdbuf() || osbuf == cerr.rdbuf()) {
		static const bool cerr_term = isatty(fileno(stderr)) != 0;
		return cerr_term;
	}
#endif
	return false;
}

template<typename T>
using enableStd = typename std::enable_if<
	std::is_same<T, adj::style>::value
	|| std::is_same<T, adj::fg>::value
	|| std::is_same<T, adj::bg>::value,
	std::ostream &>::type;

template<typename T>
inline enableStd<T>
setColor(std::ostream &os, T const value)
{
	return os << "\033[" << static_cast<int>(value) << "m";
}

} // namespace implementation

inline void
setAnsilMode(control value) noexcept
{
	implementation::ansiMode() = value;
}


template<typename T>
inline implementation::enableStd<T>
operator<<(std::ostream &os, const T value) {
	switch (implementation::ansiMode())
	{
		case control::Auto:
			return implementation::supportsColor()
				&& implementation::isTerminal(os.rdbuf())
				? implementation::setColor(os, value)
				: os;
		case control::Force:
			return implementation::setColor(os, value);
		default:
			return os;
	}
}

} // namespace adj
