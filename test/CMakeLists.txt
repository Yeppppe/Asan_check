cmake_minimum_required(VERSION 3.10)
project(AsanTest)

# 设置C++标准
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 添加调试符号并禁用优化
set(CMAKE_BUILD_TYPE Debug)
# 确保包含完整的调试信息，禁用优化
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -g3 -gdwarf-4 -O0")
# 强制所有构建类型都包含调试信息
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g3 -gdwarf-4")

# 创建可执行文件
add_executable(asan_test main.cpp)

# 添加线程库
find_package(Threads REQUIRED)
target_link_libraries(asan_test PRIVATE Threads::Threads)

# 添加ASAN选项
option(USE_ASAN "启用Address Sanitizer" ON)
option(USE_HWASAN "启用Hardware-assisted Address Sanitizer" OFF)
option(USE_CUSTOM_ASAN "使用自定义ASAN库路径" OFF)
set(CUSTOM_ASAN_LIB_PATH "" CACHE PATH "自定义ASAN库的路径")
set(CUSTOM_ASAN_INCLUDE_PATH "" CACHE PATH "自定义ASAN头文件的路径")

if(USE_ASAN)
    if(USE_CUSTOM_ASAN)
        if(CUSTOM_ASAN_LIB_PATH STREQUAL "")
            message(FATAL_ERROR "启用自定义ASAN库时必须设置CUSTOM_ASAN_LIB_PATH")
        endif()
        
        message(STATUS "使用自定义ASAN库: ${CUSTOM_ASAN_LIB_PATH}")
        target_compile_options(asan_test PRIVATE -fno-omit-frame-pointer)
        
        # 添加自定义包含路径（如果提供）
        if(NOT CUSTOM_ASAN_INCLUDE_PATH STREQUAL "")
            target_include_directories(asan_test PRIVATE ${CUSTOM_ASAN_INCLUDE_PATH})
        endif()
        
        # 直接链接到指定的ASAN库文件
        target_link_libraries(asan_test PRIVATE ${CUSTOM_ASAN_LIB_PATH})
    else()
        message(STATUS "启用Address Sanitizer")
        target_compile_options(asan_test PRIVATE -fsanitize=address -fno-omit-frame-pointer)
        set_target_properties(asan_test PROPERTIES LINK_FLAGS "-fsanitize=address")
    endif()
endif()

if(USE_HWASAN)
    message(STATUS "启用Hardware-assisted Address Sanitizer")
    target_compile_options(asan_test PRIVATE -fsanitize=hwaddress -fno-omit-frame-pointer)
    set_target_properties(asan_test PROPERTIES LINK_FLAGS "-fsanitize=hwaddress")
endif()

# 添加其他常用的编译选项，确保包含调试信息
target_compile_options(asan_test PRIVATE 
    -Wall 
    -Wextra 
    -fno-inline  # 禁用内联以获得更好的调试体验
    -fno-eliminate-unused-debug-symbols  # 保留所有调试符号
)

# 指定不剥离符号表
set_target_properties(asan_test PROPERTIES LINK_FLAGS_DEBUG "-rdynamic")

# 安装目标
install(TARGETS asan_test DESTINATION bin) 