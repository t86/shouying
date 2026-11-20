#include "terminal_identity.h"

#include <flutter/encodable_value.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <string>

namespace {

std::string ReadMachineCode() {
  // Use the same registry view for both 32-bit and 64-bit app builds.
  wchar_t buffer[256] = {};
  DWORD bytes = static_cast<DWORD>(sizeof(buffer));
  const auto status = RegGetValueW(
      HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\Cryptography", L"MachineGuid",
      RRF_RT_REG_SZ | RRF_SUBKEY_WOW6464KEY, nullptr, buffer, &bytes);
  if (status != ERROR_SUCCESS) return {};

  const std::wstring guid(buffer);
  if (guid.empty() || guid.find_first_not_of(L" \t\r\n") == std::wstring::npos) {
    return {};
  }
  const int length = static_cast<int>(guid.size());
  const int size = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, guid.data(),
                                     length, nullptr, 0, nullptr, nullptr);
  if (size <= 0) return {};
  std::string value(static_cast<size_t>(size), '\0');
  if (WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, guid.data(), length,
                          value.data(), size, nullptr, nullptr) != size) {
    return {};
  }
  return "windows:" + value;
}

}  // namespace

TerminalIdentity::TerminalIdentity(flutter::BinaryMessenger* messenger) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "shouyin/terminal_identity",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([](const auto& call, auto result) {
    if (call.method_name() != "getMachineCode") {
      result->NotImplemented();
      return;
    }
    const auto code = ReadMachineCode();
    if (code.empty()) {
      result->Error("terminal_identity_unavailable", "无法获取终端机器码");
      return;
    }
    result->Success(flutter::EncodableValue(code));
  });
}

TerminalIdentity::~TerminalIdentity() {
  channel_->SetMethodCallHandler(nullptr);
}
