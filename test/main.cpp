#include <iostream>
#include <stdlib.h>
#include <string.h>
#include <thread>

// 使用已释放的内存 (Use-After-Free)
void test_use_after_free() {
    std::cout << "测试 Use-After-Free 错误" << std::endl;
    char* volatile p = new char[10];
    delete[] p;
    p[5] = 42;  // 使用已释放的内存
}

// 堆缓冲区溢出 (Heap Buffer Overflow)
void test_heap_buffer_overflow() {
    std::cout << "测试堆缓冲区溢出错误" << std::endl;
    char* volatile p = new char[16];
    p[16] = 42;  // 越界写入
    delete[] p;
}

// 堆缓冲区溢出读取循环 (Heap Buffer Overflow Read Loop)
void test_heap_buffer_overflow_read_loop() {
    std::cout << "测试堆缓冲区溢出读取循环" << std::endl;
    for (int i = 0; i < 10; ++i) {
        char* volatile p = new char[16];
        volatile char x = p[32];  // 越界读取
        x++;
        delete[] p;
    }
}

// 重复释放 (Double Free)
void test_double_free() {
    std::cout << "测试重复释放错误" << std::endl;
    char* volatile p = new char[16];
    delete[] p;
    delete[] p;  // 重复释放同一内存
}

// 空指针解引用 (Null Pointer Dereference)
void test_null_deref() {
    std::cout << "测试空指针解引用错误" << std::endl;
    char* volatile p = nullptr;
    p[42] = 1;  // 空指针解引用
}

// 内存泄漏 (Memory Leak)
void test_memory_leak() {
    std::cout << "测试内存泄漏" << std::endl;
    char* p = new char[100];  // 分配内存但不释放
    // 没有对应的 delete[] p;
}

// 栈缓冲区溢出 (Stack Buffer Overflow)
void test_stack_buffer_overflow() {
    std::cout << "测试栈缓冲区溢出错误" << std::endl;
    char buffer[10];
    strcpy(buffer, "这是一个很长的字符串，会导致栈缓冲区溢出");  // 栈溢出
}

// 多线程 UAF 循环测试
static void run_uaf_loop() {
    constexpr int kLoopCount = 10;
    constexpr int kAllocCount = 100;
    volatile char sink;
    char** p = new char*[kAllocCount];
    for (int j = 0; j < kLoopCount; ++j) {
        for (int i = 0; i < kAllocCount; ++i)
            p[i] = new char[128];
        for (int i = 0; i < kAllocCount; ++i)
            delete[] p[i];
        for (int i = 0; i < kAllocCount; ++i)
            sink = p[i][42];  // UAF
    }
    delete[] p;
}

void test_uaf_loop() {
    std::cout << "测试多线程 Use-After-Free 循环" << std::endl;
    std::thread t(run_uaf_loop);
    t.join();
}

int main(int argc, char** argv) {
    std::cout << "ASan 测试程序开始运行" << std::endl;
    
    if (argc < 2) {
        std::cout << "用法: " << argv[0] << " <测试编号>" << std::endl;
        std::cout << "可用测试:" << std::endl;
        std::cout << "  1: Use-After-Free" << std::endl;
        std::cout << "  2: 堆缓冲区溢出" << std::endl;
        std::cout << "  3: 堆缓冲区溢出读取循环" << std::endl;
        std::cout << "  4: 重复释放" << std::endl;
        std::cout << "  5: 空指针解引用" << std::endl;
        std::cout << "  6: 内存泄漏" << std::endl;
        std::cout << "  7: 栈缓冲区溢出" << std::endl;
        std::cout << "  8: 多线程 UAF 循环" << std::endl;
        return 1;
    }

    int test_num = atoi(argv[1]);
    switch (test_num) {
        case 1: test_use_after_free(); break;
        case 2: test_heap_buffer_overflow(); break;
        case 3: test_heap_buffer_overflow_read_loop(); break;
        case 4: test_double_free(); break;
        case 5: test_null_deref(); break;
        case 6: test_memory_leak(); break;
        case 7: test_stack_buffer_overflow(); break;
        case 8: test_uaf_loop(); break;
        default:
            std::cout << "无效的测试编号: " << test_num << std::endl;
            return 1;
    }

    std::cout << "测试完成" << std::endl;
    return 0;
} 