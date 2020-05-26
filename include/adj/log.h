#pragma once
#include <iostream>
#include <atomic>
#include "kleurtjes.h"

namespace adj
{

enum class logLevel : int
{
	DEBUG = 0, WARN, ERROR, INFO, NONE
};

namespace implementation
{

const char* logHeaders[]
{
	"[DEBUG] ", "[WARN ] ", "[ERROR] ", "[INFO ] "
};

const fg logColors[]
{
	fg::blue, fg::yellow, fg::red, fg::green
};

std::atomic<logLevel> &
getLogLevel()
{
	static std::atomic<logLevel> level(logLevel::DEBUG);
	return level;
}

std::ostream *&
getLogStream()
{
	static std::ostream *stream = &std::cerr;
	return stream;
}

class Logger
{
public:
	Logger(logLevel lvl) : lvl(lvl) {}

	template<typename T>
	Logger &log(T message)
	{
		if (lvl >= getLogLevel())
			*getLogStream() << style::reset
			                << logColors[static_cast<int>(lvl)]
			                << logHeaders[static_cast<int>(lvl)]
			                << message << style::reset
			                << std::endl;
		return *this;
	}

private:
	logLevel lvl;

};

} // namespace implementation

implementation::Logger error(logLevel::ERROR), warn(logLevel::WARN),
                       debug(logLevel::DEBUG), info(logLevel::INFO);

template<typename T>
implementation::Logger &operator<<(implementation::Logger logger, T message)
{
	return logger.log(message);
}

inline void
setLogLevel(logLevel level)
{
	implementation::getLogLevel() = level;
}

inline void
setLogStream(std::ostream& stream)
{
	implementation::getLogStream() = &stream;
}

} // namespace adj
