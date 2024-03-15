#include "library.h"
#include "Memory.hpp"
using namespace godot;
using std::string;

// this one is MANDATORY.
void GDNScraper::_init() {
}

Memory Memory;
int processID = -1;
HANDLE processHandle;
int baseAddress;

int GDNScraper::open(String processName) {
    char* TARGET_PROCESS_NAME = processName.alloc_c_string();

    // must be greater than 0
    processID = Memory.GetProcessId(TARGET_PROCESS_NAME);
    if (processID == -1)
        return -1;

    processHandle = OpenProcess(PROCESS_ALL_ACCESS, false, processID);
    if (processHandle == NULL)
        return -1;

    baseAddress = Memory.GetModuleBase(processHandle, (string)TARGET_PROCESS_NAME);
    return baseAddress;
}
int64_t GDNScraper::scrape(int address, int size) {
    return Memory.Read(processHandle, baseAddress + address, size);
}
int GDNScraper::getLastError() {
    return Memory.lastError;
}

void GDNScraper::_register_methods() {
    register_method("open", &GDNScraper::open);
    register_method("scrape", &GDNScraper::scrape);
    register_method("getLastError", &GDNScraper::getLastError);
}

bool process_setup() {
    return Memory.GetDebugPrivileges();
}