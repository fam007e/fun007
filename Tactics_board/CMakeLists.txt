cmake_minimum_required(VERSION 3.10)
project(TacticsBoard)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

include_directories(include)

file(GLOB SOURCES "source/*.cpp")
add_executable(tactics_board ${SOURCES})

find_package(SFML 2.5 COMPONENTS graphics window system REQUIRED)
target_link_libraries(tactics_board sfml-graphics sfml-window sfml-system)
