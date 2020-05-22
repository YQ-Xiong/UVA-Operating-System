cmake_minimum_required(VERSION 3.14)
project(floral C)

set(CMAKE_C_STANDARD 11)

include_directories(include)
include_directories(test/include)

add_executable(floral
        include/floral.h
        include/main.h
        include/thread.h
        include/utils.h
        src/main.c
        src/thread.c
        test/include/test.h
        test/src/phase1_tests.c
        test/src/phase2_tests.c
        test/src/phase3_tests.c
        test/src/phase4_tests.c
        test/src/phase5_tests.c
        test/src/test.c
        test/src/test_utils.c)
