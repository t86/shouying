#ifndef RUNNER_TERMINAL_IDENTITY_H_
#define RUNNER_TERMINAL_IDENTITY_H_

#include <flutter/binary_messenger.h>
#include <flutter/method_channel.h>

#include <memory>

// Reads the native identity only on explicit terminal-registration requests.
class TerminalIdentity {
 public:
  explicit TerminalIdentity(flutter::BinaryMessenger* messenger);
  ~TerminalIdentity();

 private:
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_TERMINAL_IDENTITY_H_
