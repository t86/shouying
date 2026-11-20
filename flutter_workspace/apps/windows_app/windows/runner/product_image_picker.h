#ifndef RUNNER_PRODUCT_IMAGE_PICKER_H_
#define RUNNER_PRODUCT_IMAGE_PICKER_H_

#include <flutter/binary_messenger.h>
#include <flutter/method_channel.h>

#include <memory>
#include <string>
#include <unordered_map>

#include <windows.h>

// Native file dialog for BMS product images. Matches the Android
// shouyin/product_images contract: pickImages / readImage / releaseImages.
class ProductImagePicker {
 public:
  ProductImagePicker(flutter::BinaryMessenger* messenger, HWND owner);
  ~ProductImagePicker();

 private:
  void Handle(const flutter::MethodCall<flutter::EncodableValue>& call,
              std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void Pick(bool multiple,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void Read(const flutter::EncodableMap* args,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void Release(const flutter::EncodableMap* args,
               std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  HWND owner_ = nullptr;
  bool busy_ = false;
  std::unordered_map<std::string, std::wstring> handles_;
};

#endif  // RUNNER_PRODUCT_IMAGE_PICKER_H_
