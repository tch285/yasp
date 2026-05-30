cmake_minimum_required(VERSION 3.16)

project(yenv C)

include(GNUInstallDirs)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

add_executable(yenv yenv.c)

install(TARGETS yenv
	RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
