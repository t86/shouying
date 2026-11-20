#include "product_image_picker.h"

#include <flutter/encodable_value.h>
#include <flutter/standard_method_codec.h>

#include <shobjidl.h>
#include <shlobj.h>

#include <algorithm>
#include <fstream>
#include <vector>

namespace {

constexpr int kMaxImages = 200;
constexpr size_t kMaxBytes = 500 * 1024;

std::string WideToUtf8(const std::wstring& value) {
  if (value.empty()) return {};
  const int size = WideCharToMultiByte(CP_UTF8, 0, value.c_str(), -1, nullptr,
                                        0, nullptr, nullptr);
  if (size <= 1) return {};
  std::string out(static_cast<size_t>(size - 1), '\0');
  WideCharToMultiByte(CP_UTF8, 0, value.c_str(), -1, out.data(), size, nullptr,
                      nullptr);
  return out;
}

std::wstring NewId() {
  GUID guid;
  if (FAILED(CoCreateGuid(&guid))) return L"";
  wchar_t buffer[64];
  if (StringFromGUID2(guid, buffer, 64) == 0) return L"";
  return buffer;
}

bool IsPngOrJpeg(const std::vector<uint8_t>& bytes) {
  const bool jpeg = bytes.size() >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 &&
                    bytes[2] == 0xFF;
  const bool png = bytes.size() >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50 &&
                   bytes[2] == 0x4E && bytes[3] == 0x47 && bytes[4] == 0x0D &&
                   bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A;
  return jpeg || png;
}

std::wstring FileNameOf(const std::wstring& path) {
  const auto slash = path.find_last_of(L"\\/");
  return slash == std::wstring::npos ? path : path.substr(slash + 1);
}

}  // namespace

ProductImagePicker::ProductImagePicker(flutter::BinaryMessenger* messenger,
                                       HWND owner)
    : owner_(owner) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "shouyin/product_images",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) { Handle(call, std::move(result)); });
}

ProductImagePicker::~ProductImagePicker() {
  channel_->SetMethodCallHandler(nullptr);
  handles_.clear();
}

void ProductImagePicker::Handle(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
  if (call.arguments() && args == nullptr) {
    result->Error("invalid_arguments", "图片选择参数无效");
    return;
  }
  if (call.method_name() == "pickImages") {
    bool multiple = false;
    if (args != nullptr) {
      const auto it = args->find(flutter::EncodableValue("multiple"));
      if (it != args->end()) {
        if (!std::holds_alternative<bool>(it->second)) {
          result->Error("invalid_arguments", "图片选择参数无效");
          return;
        }
        multiple = std::get<bool>(it->second);
      }
    }
    Pick(multiple, std::move(result));
    return;
  }
  if (call.method_name() == "readImage") {
    Read(args, std::move(result));
    return;
  }
  if (call.method_name() == "releaseImages") {
    Release(args, std::move(result));
    return;
  }
  result->NotImplemented();
}

void ProductImagePicker::Pick(
    bool multiple,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (busy_) {
    result->Error("picker_busy", "图片选择器已打开");
    return;
  }
  busy_ = true;
  IFileOpenDialog* dialog = nullptr;
  HRESULT hr = CoCreateInstance(CLSID_FileOpenDialog, nullptr, CLSCTX_INPROC_SERVER,
                                IID_PPV_ARGS(&dialog));
  if (FAILED(hr) || dialog == nullptr) {
    busy_ = false;
    result->Error("picker_unavailable", "设备没有可用的图片选择器");
    return;
  }
  DWORD options = 0;
  dialog->GetOptions(&options);
  options |= FOS_FORCEFILESYSTEM | FOS_FILEMUSTEXIST | FOS_PATHMUSTEXIST;
  if (multiple) options |= FOS_ALLOWMULTISELECT;
  dialog->SetOptions(options);
  COMDLG_FILTERSPEC filters[] = {
      {L"PNG 或 JPEG", L"*.png;*.jpg;*.jpeg"},
  };
  dialog->SetFileTypes(1, filters);
  dialog->SetTitle(L"选择商品图片");
  hr = dialog->Show(owner_);
  if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
    dialog->Release();
    busy_ = false;
    result->Success();
    return;
  }
  if (FAILED(hr)) {
    dialog->Release();
    busy_ = false;
    result->Error("picker_unavailable", "设备没有可用的图片选择器");
    return;
  }
  std::vector<std::wstring> paths;
  if (multiple) {
    IShellItemArray* items = nullptr;
    if (SUCCEEDED(dialog->GetResults(&items)) && items != nullptr) {
      DWORD count = 0;
      items->GetCount(&count);
      if (count > kMaxImages) {
        items->Release();
        dialog->Release();
        busy_ = false;
        result->Error("too_many_images", "每批最多选择200张图片");
        return;
      }
      for (DWORD i = 0; i < count; ++i) {
        IShellItem* item = nullptr;
        if (FAILED(items->GetItemAt(i, &item)) || item == nullptr) continue;
        PWSTR name = nullptr;
        if (SUCCEEDED(item->GetDisplayName(SIGDN_FILESYSPATH, &name)) && name) {
          paths.emplace_back(name);
          CoTaskMemFree(name);
        }
        item->Release();
      }
      items->Release();
    }
  } else {
    IShellItem* item = nullptr;
    if (SUCCEEDED(dialog->GetResult(&item)) && item != nullptr) {
      PWSTR name = nullptr;
      if (SUCCEEDED(item->GetDisplayName(SIGDN_FILESYSPATH, &name)) && name) {
        paths.emplace_back(name);
        CoTaskMemFree(name);
      }
      item->Release();
    }
  }
  dialog->Release();
  if (!multiple && paths.size() > 1) {
    busy_ = false;
    result->Error("too_many_images", "图片数量超出本次选择范围");
    return;
  }
  flutter::EncodableList images;
  for (const auto& path : paths) {
    const std::wstring id = NewId();
    if (id.empty()) continue;
    handles_[WideToUtf8(id)] = path;
    WIN32_FILE_ATTRIBUTE_DATA info;
    flutter::EncodableValue size = flutter::EncodableValue();
    if (GetFileAttributesExW(path.c_str(), GetFileExInfoStandard, &info)) {
      const ULONGLONG bytes =
          (static_cast<ULONGLONG>(info.nFileSizeHigh) << 32) | info.nFileSizeLow;
      if (bytes <= static_cast<ULONGLONG>(INT_MAX)) {
        size = flutter::EncodableValue(static_cast<int32_t>(bytes));
      }
    }
    flutter::EncodableMap row;
    row[flutter::EncodableValue("id")] = flutter::EncodableValue(WideToUtf8(id));
    row[flutter::EncodableValue("name")] =
        flutter::EncodableValue(WideToUtf8(FileNameOf(path)));
    row[flutter::EncodableValue("size")] = size;
    images.push_back(flutter::EncodableValue(row));
  }
  busy_ = false;
  result->Success(flutter::EncodableValue(images));
}

void ProductImagePicker::Read(
    const flutter::EncodableMap* args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  std::string id;
  if (args != nullptr) {
    const auto it = args->find(flutter::EncodableValue("id"));
    if (it != args->end() && std::holds_alternative<std::string>(it->second)) {
      id = std::get<std::string>(it->second);
    }
  }
  const auto found = handles_.find(id);
  if (found == handles_.end()) {
    result->Error("image_released", "图片选择已失效，请重新选择");
    return;
  }
  std::ifstream input(found->second, std::ios::binary);
  if (!input) {
    result->Error("image_read_failed", "图片无法读取，请选择小于500KB的PNG或JPEG图片");
    return;
  }
  std::vector<uint8_t> bytes;
  bytes.reserve(8192);
  char buffer[8192];
  while (input) {
    input.read(buffer, sizeof(buffer));
    const auto count = input.gcount();
    if (count <= 0) break;
    if (bytes.size() + static_cast<size_t>(count) >= kMaxBytes) {
      result->Error("image_read_failed", "图片无法读取，请选择小于500KB的PNG或JPEG图片");
      return;
    }
    bytes.insert(bytes.end(), buffer, buffer + count);
  }
  if (!IsPngOrJpeg(bytes)) {
    result->Error("image_read_failed", "图片无法读取，请选择小于500KB的PNG或JPEG图片");
    return;
  }
  result->Success(flutter::EncodableValue(bytes));
}

void ProductImagePicker::Release(
    const flutter::EncodableMap* args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (args == nullptr || args->find(flutter::EncodableValue("ids")) == args->end()) {
    handles_.clear();
    result->Success();
    return;
  }
  const auto it = args->find(flutter::EncodableValue("ids"));
  const auto* ids = std::get_if<flutter::EncodableList>(&it->second);
  if (ids == nullptr) {
    result->Error("invalid_arguments", "图片释放参数无效");
    return;
  }
  for (const auto& raw : *ids) {
    if (const auto* id = std::get_if<std::string>(&raw)) handles_.erase(*id);
  }
  result->Success();
}
