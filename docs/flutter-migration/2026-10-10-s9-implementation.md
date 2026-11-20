# S9 功能实现（2026-10-10）

用户已明确本轮处理S9，业务验收后续进行；三项从可选待确认纳入当前实现。

- 超管登录：独立stk、安全持久化、在线验证恢复、令牌失效与退出，普通员工会话不授予超管权限。系统选择页及登录页可进入/appinfo，成功到/ManagementSystem/appinfo/smgr。
- 用户管理：递归部门真实ID、岗位与姓名查询、重置、展开员工，原岗位/管理员/员工管理操作、改密与退出。旧页面或旧会话不能提交后来用户的操作。
- 终端注册：Android ANDROID_ID（无值时私有安装UUID）、Windows MachineGuid原生通道；注册auth_code/machine_code/remark保持原接口；独立存储auth_mode，随后重新/term/auth。已注册但保存或授权失败时保留已成功结果，仅重试后续步骤。
- 浏览器原实现依赖atool，本身不能读取真实机器码；Web保留清楚提示。原生机器码不会由共享常量或手工假码代替。

复用现有ProtocolClient、SecureCredentialBackend和公共设备接口，Windows/Android均注入原生identity服务。默认会话守卫在凭据等待后及实际网络派发前检查；真正权限、密码或设备注册操作没有被执行。

必要实现检查：超管会话/API/入口37项、管理页/模型14项、原生通道模拟9项、注册流程/入口7项、注册设置1项均通过（部分入口检查重叠，不合算全库测试数）。相关Dart静态检查无error/warning，模块边界0违规；Flutter Web已完成编译并在本地8183提供服务。未执行本轮全库回归、Windows原生编译或业务验收。

主要源码：super_admin_loader.dart、super_admin_api.dart、super_admin_views.dart、super_admin_login_screen.dart、terminal_register_screen.dart；Web/native_client_shell路由；terminal_registration_settings.dart与各端TerminalIdentityService/native通道。

看板三项更新为已编码未确认，保留人工验收状态。S9代码存在不等于已通过门店权限和实机验收。
