import 'package:flutter/material.dart';
import 'package:mathmate/services/auth_service.dart';

/// 登录/注册页面 —— 支持：
/// - 账号密码登录
/// - 邀请码直登（开发者模式）
/// - 邮箱/手机验证码注册
enum _AuthMode { login, register, devLogin }

class LoginPage extends StatefulWidget {
  final void Function(bool loggedIn)? onLoginResult;
  const LoginPage({super.key, this.onLoginResult});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 模式
  _AuthMode _mode = _AuthMode.login;

  // 登录
  final _loginUser = TextEditingController();
  final _loginPass = TextEditingController();
  bool _loginLoading = false;
  String? _loginError;

  // 开发者直登
  final _devCode = TextEditingController();
  bool _devLoading = false;
  String? _devError;

  // 注册 —— 多步骤
  int _regStep = 0; // 0=输入邮箱+邀请码, 1=验证码, 2=设置密码
  final _regEmail = TextEditingController();
  final _regInvite = TextEditingController();
  final _regCode = TextEditingController();
  final _regUser = TextEditingController();
  final _regPass = TextEditingController();
  bool _regLoading = false;
  String? _regError;
  String? _regMsg;

  @override
  void dispose() {
    _loginUser.dispose(); _loginPass.dispose();
    _devCode.dispose();
    _regEmail.dispose(); _regInvite.dispose();
    _regCode.dispose(); _regUser.dispose(); _regPass.dispose();
    super.dispose();
  }

  // ==================== 登录 ====================

  Future<void> _doLogin() async {
    final u = _loginUser.text.trim();
    final p = _loginPass.text.trim();
    if (u.isEmpty || p.isEmpty) { setState(() => _loginError = '请输入用户名和密码'); return; }
    setState(() { _loginLoading = true; _loginError = null; });
    final r = await AuthService().login(username: u, password: p);
    if (!mounted) return;
    setState(() => _loginLoading = false);
    if (r.ok) { widget.onLoginResult?.call(true); }
    else { setState(() => _loginError = r.error); }
  }

  // ==================== 开发者直登 ====================

  Future<void> _doDevLogin() async {
    final code = _devCode.text.trim();
    if (code.isEmpty) { setState(() => _devError = '请输入开发者邀请码'); return; }
    setState(() { _devLoading = true; _devError = null; });
    final r = await AuthService().devLogin(inviteCode: code);
    if (!mounted) return;
    setState(() => _devLoading = false);
    if (r.ok) { widget.onLoginResult?.call(true); }
    else { setState(() => _devError = r.error); }
  }

  // ==================== 注册 Step 0：发送验证码 ====================

  Future<void> _regStep0() async {
    final email = _regEmail.text.trim();
    final invite = _regInvite.text.trim();
    if (email.isEmpty) { setState(() => _regError = '请输入邮箱或手机号'); return; }
    if (invite.isEmpty) { setState(() => _regError = '请输入邀请码'); return; }

    setState(() { _regLoading = true; _regError = null; _regMsg = null; });
    final r = await AuthService().sendCode(email: email);
    if (!mounted) return;
    setState(() => _regLoading = false);
    if (r['ok'] == true) {
      setState(() { _regStep = 1; _regMsg = r['message'] as String?; });
    } else {
      setState(() => _regError = r['error'] as String?);
    }
  }

  // ==================== 注册 Step 1：验证验证码 ====================

  Future<void> _regStep1() async {
    final email = _regEmail.text.trim();
    final code = _regCode.text.trim();
    if (code.length != 6) { setState(() => _regError = '请输入 6 位验证码'); return; }

    setState(() { _regLoading = true; _regError = null; });
    final r = await AuthService().verifyCode(email: email, code: code);
    if (!mounted) return;
    setState(() => _regLoading = false);
    if (r['ok'] == true) {
      setState(() { _regStep = 2; _regMsg = '验证通过，请设置账号信息'; });
    } else {
      setState(() => _regError = r['error'] as String?);
    }
  }

  // ==================== 注册 Step 2：完成注册 ====================

  Future<void> _regStep2() async {
    final u = _regUser.text.trim();
    final p = _regPass.text.trim();
    final email = _regEmail.text.trim();
    final invite = _regInvite.text.trim();
    final code = _regCode.text.trim();

    if (u.length < 2) { setState(() => _regError = '用户名至少 2 个字符'); return; }
    if (p.length < 6) { setState(() => _regError = '密码至少 6 位'); return; }

    setState(() { _regLoading = true; _regError = null; });
    final r = await AuthService().register(
      username: u, password: p, email: email, inviteCode: invite, code: code,
    );
    if (!mounted) return;
    setState(() => _regLoading = false);
    if (r.ok) {
      widget.onLoginResult?.call(true);
    } else {
      setState(() => _regError = r.error);
    }
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: <Widget>[
          TextButton(
            onPressed: () => widget.onLoginResult?.call(false),
            child: const Text('跳过，直接使用', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const ClipOval(
                    child: Image(image: AssetImage('assets/app_icon_final.png'), width: 72, height: 72),
                  ),
                  const SizedBox(height: 8),
                  Text('MathMate 数学学习助手', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const SizedBox(height: 24),
                  // 模式切换
                  _buildModeTabs(cs),
                  const SizedBox(height: 24),
                  // 内容区
                  switch (_mode) {
                    _AuthMode.login => _buildLogin(cs),
                    _AuthMode.devLogin => _buildDevLogin(cs),
                    _AuthMode.register => _buildRegister(cs),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTabs(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: <Widget>[
          _tabBtn('登录', _AuthMode.login, cs),
          _tabBtn('注册', _AuthMode.register, cs),
          _tabBtn('开发者', _AuthMode.devLogin, cs),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, _AuthMode mode, ColorScheme cs) {
    final active = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: active ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.6)),
          ),
        ),
      ),
    );
  }

  // ==================== 登录表单 ====================

  Widget _buildLogin(ColorScheme cs) {
    return Column(children: <Widget>[
      if (_loginError != null) _err(_loginError!),
      _field(_loginUser, '用户名', cs),
      const SizedBox(height: 12),
      _field(_loginPass, '密码', cs, obscure: true, onSubmitted: (_) => _doLogin()),
      const SizedBox(height: 20),
      _btn('登录', _loginLoading, _doLogin, cs),
    ]);
  }

  // ==================== 开发者直登 ====================

  Widget _buildDevLogin(ColorScheme cs) {
    return Column(children: <Widget>[
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
        child: Row(children: <Widget>[
          Icon(Icons.info_outline, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(child: Text('输入开发者邀请码即可直接进入，跳过注册流程', style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7)))),
        ]),
      ),
      if (_devError != null) _err(_devError!),
      _field(_devCode, '开发者邀请码', cs, onSubmitted: (_) => _doDevLogin()),
      const SizedBox(height: 20),
      _btn('进入开发者模式', _devLoading, _doDevLogin, cs),
    ]);
  }

  // ==================== 注册表单（多步骤） ====================

  Widget _buildRegister(ColorScheme cs) {
    // Step 指示器
    final steps = ['第一步：输入邮箱 + 邀请码', '第二步：输入验证码', '第三步：设置账号密码'];
    return Column(children: <Widget>[
      // 进度条
      Row(children: List.generate(3, (i) => Expanded(child: Container(
        height: 4,
        margin: EdgeInsets.only(left: i > 0 ? 4 : 0, right: i < 2 ? 4 : 0),
        decoration: BoxDecoration(
          color: i <= _regStep ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(2),
        ),
      )))),
      const SizedBox(height: 12),
      Text(steps[_regStep], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary)),
      const SizedBox(height: 16),

      if (_regMsg != null)
        Container(
          padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
          child: Row(children: <Widget>[
            Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
            const SizedBox(width: 8),
            Expanded(child: Text(_regMsg!, style: TextStyle(fontSize: 13, color: Colors.green.shade700))),
          ]),
        ),
      if (_regError != null) _err(_regError!),

      // Step 0
      if (_regStep == 0) ...[
        _field(_regEmail, '邮箱或手机号', cs, hint: '用于接收验证码', keyboard: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _field(_regInvite, '邀请码', cs, hint: '输入注册邀请码'),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _mode = _AuthMode.devLogin),
            icon: const Icon(Icons.code, size: 14),
            label: const Text('我有开发者邀请码', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(height: 2),
        _btn('获取验证码', _regLoading, _regStep0, cs),
      ],

      // Step 1
      if (_regStep == 1) ...[
        Text('验证码已发送至 ${_regEmail.text.trim()}，请查收', style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 12),
        _field(_regCode, '6 位验证码', cs, hint: '请输入收到的验证码', keyboard: TextInputType.number, maxLen: 6, onSubmitted: (_) => _regStep1()),
        const SizedBox(height: 20),
        Row(children: <Widget>[
          Expanded(child: OutlinedButton(onPressed: () => setState(() => _regStep = 0), child: const Text('上一步'))),
          const SizedBox(width: 12),
          Expanded(child: _btn('验证', _regLoading, _regStep1, cs)),
        ]),
      ],

      // Step 2
      if (_regStep == 2) ...[
        _field(_regUser, '用户名', cs, hint: '至少 2 个字符'),
        const SizedBox(height: 12),
        _field(_regPass, '密码', cs, hint: '至少 6 位', obscure: true, onSubmitted: (_) => _regStep2()),
        const SizedBox(height: 20),
        Row(children: <Widget>[
          Expanded(child: OutlinedButton(onPressed: () => setState(() => _regStep = 1), child: const Text('上一步'))),
          const SizedBox(width: 12),
          Expanded(child: _btn('完成注册', _regLoading, _regStep2, cs)),
        ]),
      ],
    ]);
  }

  // ==================== 组件 ====================

  Widget _field(TextEditingController ctrl, String label, ColorScheme cs,
      {bool obscure = false, String? hint, TextInputType? keyboard, int? maxLen, void Function(String)? onSubmitted}) {
    return TextField(
      controller: ctrl, obscureText: obscure,
      keyboardType: keyboard, maxLength: maxLen,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        filled: true, fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        counterText: '',
      ),
    );
  }

  Widget _btn(String label, bool loading, VoidCallback onTap, ColorScheme cs) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: FilledButton(
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _err(String msg) => Container(
    width: double.infinity, margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
    child: Row(children: <Widget>[
      Icon(Icons.error_outline, size: 16, color: Colors.red.shade400),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: TextStyle(fontSize: 13, color: Colors.red.shade700))),
    ]),
  );
}
