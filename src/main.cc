#include <iostream>
#include "adj/kleurtjes.h"
#include "adj/log.h"

int main() {
	using namespace adj;
	using std::cout;

	adj::setLogLevel(adj::logLevel::DEBUG);
	adj::setLogStream(std::cout);

	adj::error << "This is an error" << " with extra output";
	adj::warn  << "This is a warning";
	adj::debug << "This is a debug message";
	adj::info  << "This is an info message";

	cout << style::bold << fg::blue << "Hello World" << style::reset << std::endl;
	return 0;
}
