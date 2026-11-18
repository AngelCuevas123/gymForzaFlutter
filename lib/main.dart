import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const navy=Color(0xFF101827), card=Color(0xFF1C293B), green=Color(0xFF35D07F), red=Color(0xFFFF626B), muted=Color(0xFF9BA8B8);
const api='https://gymforza.onrender.com/';
const sbUrl=String.fromEnvironment('SUPABASE_URL'), sbKey=String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
 WidgetsFlutterBinding.ensureInitialized();
 var ready=sbUrl.isNotEmpty&&sbKey.isNotEmpty;
 if(ready){try{await Supabase.initialize(url:sbUrl,publishableKey:sbKey);}catch(e){debugPrint('Supabase: $e');ready=false;}}
 runApp(App(configured:ready));
}
class App extends StatelessWidget {
 const App({super.key,required this.configured}); final bool configured;
 @override Widget build(BuildContext context)=>MaterialApp(title:'Gym Forza Access',debugShowCheckedModeBanner:false,
 theme:ThemeData(brightness:Brightness.dark,scaffoldBackgroundColor:navy,colorScheme:const ColorScheme.dark(primary:green,surface:card,error:red),useMaterial3:true,
 inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:card,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:green)))),
 home:configured?const Gate():const Setup());
}
class Brand extends StatelessWidget {
 const Brand({super.key,this.small=false}); final bool small;
 @override Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Text('GYM FORZA',style:TextStyle(fontSize:small?22:30,fontWeight:FontWeight.w900)),
 const Text('CONTROL DE ACCESO',style:TextStyle(color:green,fontSize:11,fontWeight:FontWeight.bold,letterSpacing:2))]);
}
class Setup extends StatelessWidget {
 const Setup({super.key});
 @override Widget build(BuildContext context)=>const Scaffold(body:Center(child:Padding(padding:EdgeInsets.all(26),child:Column(mainAxisSize:MainAxisSize.min,children:[
 Brand(),SizedBox(height:24),Icon(Icons.settings,color:green,size:40),SizedBox(height:12),
 Text('Falta configurar Supabase',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),
 SizedBox(height:10),Text('Ejecuta con --dart-define=SUPABASE_URL y --dart-define=SUPABASE_PUBLISHABLE_KEY. No guardes claves en Git.',textAlign:TextAlign.center,style:TextStyle(color:muted))
]))));
}
class Gate extends StatefulWidget {const Gate({super.key});@override State<Gate> createState()=>_GateState();}
class _GateState extends State<Gate>{
 bool loading=true;String? admin,notice;
 @override void initState(){super.initState();restore();}
 Future<void> restore() async {
  final s=Supabase.instance.client.auth.currentSession;
  if(s!=null){try{final u=await Api.me(s.accessToken);if(u['role']=='admin'){admin=(u['full_name']??u['email']??'Administrador').toString();}else{await Supabase.instance.client.auth.signOut();}}
  catch(_){await Supabase.instance.client.auth.signOut();notice='No se pudo recuperar la sesión. Inicia sesión nuevamente.';}}
  if(mounted)setState(()=>loading=false);
 }
 Future<void> logout() async {await Supabase.instance.client.auth.signOut();if(mounted)setState(()=>admin=null);}
 @override Widget build(BuildContext context){if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator(color:green)));if(admin==null)return Login(message:notice,onLogin:(n)=>setState(()=>admin=n));return Access(admin:admin!,onLogout:logout);}
}
class Login extends StatefulWidget {
 const Login({super.key,required this.onLogin,this.message});final ValueChanged<String> onLogin;final String? message;
 @override State<Login> createState()=>_LoginState();
}
class _LoginState extends State<Login>{
 final email=TextEditingController(),password=TextEditingController();bool busy=false;String? message;
 @override void initState(){super.initState();message=widget.message;}
 @override void dispose(){email.dispose();password.dispose();super.dispose();}
 Future<void> signIn() async {
  if(email.text.trim().isEmpty||password.text.isEmpty){setState(()=>message='Escribe tu correo y contraseña.');return;}
  setState((){busy=true;message=null;});
  try{
   final a=await Supabase.instance.client.auth.signInWithPassword(email:email.text.trim(),password:password.text);
   final token=a.session?.accessToken;if(token==null)throw Exception('Supabase no devolvió una sesión.');
   final u=await Api.me(token);if(u['role']!='admin'){await Supabase.instance.client.auth.signOut();throw Exception('Esta aplicación es exclusiva para administradores.');}
   widget.onLogin((u['full_name']??u['email']??'Administrador').toString());
  }on AuthException catch(e){setState(()=>message=e.message);}catch(e){setState(()=>message=e.toString().replaceFirst('Exception: ',''));}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(28),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:460),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
 const Brand(),const SizedBox(height:44),const Text('Bienvenido',style:TextStyle(fontSize:27,fontWeight:FontWeight.bold)),const SizedBox(height:7),
 const Text('Inicia sesión con tu cuenta de administrador.',style:TextStyle(color:muted)),const SizedBox(height:26),
 TextField(controller:email,enabled:!busy,keyboardType:TextInputType.emailAddress,textInputAction:TextInputAction.next,decoration:const InputDecoration(labelText:'Correo electrónico',prefixIcon:Icon(Icons.email_outlined))),
 const SizedBox(height:14),TextField(controller:password,enabled:!busy,obscureText:true,onSubmitted:(_)=>signIn(),decoration:const InputDecoration(labelText:'Contraseña',prefixIcon:Icon(Icons.lock_outline))),
 if(message!=null)...[const SizedBox(height:12),Text(message!,style:const TextStyle(color:red))],const SizedBox(height:22),
 SizedBox(height:54,child:FilledButton(onPressed:busy?null:signIn,style:FilledButton.styleFrom(backgroundColor:green,foregroundColor:navy),child:busy?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2,color:navy)):const Text('INICIAR SESIÓN',style:TextStyle(fontWeight:FontWeight.bold)))),
 const SizedBox(height:20),const Text('Acceso exclusivo para personal autorizado.',textAlign:TextAlign.center,style:TextStyle(color:muted,fontSize:12))
]))))));
}
class Access extends StatefulWidget {
 const Access({super.key,required this.admin,required this.onLogout});final String admin;final Future<void> Function() onLogout;
 @override State<Access> createState()=>_AccessState();
}
class _AccessState extends State<Access>{
 final scanner=MobileScannerController();bool busy=false,processing=false;bool? authorized;String message='Aún no se ha detectado ningún código.';Map<String,dynamic>? member;
 @override void dispose(){scanner.dispose();super.dispose();}
 Future<void> detected(BarcodeCapture c) async {
  if(processing||busy)return;String? value;for(final b in c.barcodes){if(b.rawValue!=null&&b.rawValue!.isNotEmpty){value=b.rawValue;break;}}
  if(value==null)return;processing=true;await scanner.stop();await validate(value);
 }
 Future<void> validate(String qr) async {
  setState((){busy=true;authorized=null;member=null;message='Validando código QR...';});
  try{
   if(!RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(qr))throw Exception('El contenido del QR no tiene un formato válido.');
   final s=Supabase.instance.client.auth.currentSession;if(s==null)throw const ApiException('Tu sesión expiró. Inicia sesión nuevamente.',unauthorized:true);
   final r=await Api.validate(s.accessToken,qr.toLowerCase());
   setState(() { authorized = r['authorized']==true; member = r['member'] is Map<String,dynamic> ? r['member'] as Map<String,dynamic> : null; message = (r['message'] ?? (r['authorized']==true ? 'Acceso autorizado.' : 'Acceso denegado.')).toString(); });
  } on ApiException catch(e){setState(() { authorized=false; message=e.message; });if(e.unauthorized)await widget.onLogout();}
  catch(e){setState(() { authorized=false; message=e.toString().replaceFirst('Exception: ',''); });}
  finally{if(mounted){setState(()=>busy=false);processing=false;try{await scanner.start();}catch(_){}}}
 }
 @override Widget build(BuildContext context){
  final status=authorized==true?'ACCESO AUTORIZADO':authorized==false?'ACCESO DENEGADO':busy?'VALIDANDO ACCESO':'ESPERANDO ESCANEO';
  final c=authorized==true?green:authorized==false?red:muted;
  return Scaffold(body:SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(20,12,20,14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   Row(children:[const Expanded(child:Brand(small:true)),TextButton.icon(onPressed:busy?null:widget.onLogout,icon:const Icon(Icons.logout,size:18),label:const Text('Salir'))]),
   const SizedBox(height:10),Text('Hola, '+widget.admin,style:const TextStyle(color:muted,fontSize:13)),const SizedBox(height:18),
   const Text('Escanear membresía',style:TextStyle(fontSize:23,fontWeight:FontWeight.bold)),const SizedBox(height:4),
   const Text('Coloca el código QR del socio dentro del marco.',style:TextStyle(color:muted,fontSize:13)),const SizedBox(height:16),
   Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(22),child:Stack(alignment:Alignment.center,children:[
    Container(color:card),MobileScanner(controller:scanner,onDetect:detected,errorBuilder:(context,e)=>Center(child:Text('No se pudo iniciar la cámara: '+e.errorCode.name,textAlign:TextAlign.center,style:const TextStyle(color:muted)))),
    IgnorePointer(child:Container(width:230,height:230,decoration:BoxDecoration(border:Border.all(color:green,width:3),borderRadius:BorderRadius.circular(20)))),
    Positioned(bottom:18,child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),decoration:BoxDecoration(color:navy.withValues(alpha:.85),borderRadius:BorderRadius.circular(20)),child:Text(busy?'VALIDANDO...':'CENTRA EL CÓDIGO QR',style:const TextStyle(fontSize:11,fontWeight:FontWeight.bold))))
   ]))),
   const SizedBox(height:14),Card(color:card,margin:EdgeInsets.zero,child:Padding(padding:const EdgeInsets.all(17),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(status,style:TextStyle(color:c,fontSize:12,fontWeight:FontWeight.bold,letterSpacing:.5)),const SizedBox(height:7),Text(message),
    if(authorized==true&&member!=null)...[const SizedBox(height:12),const Divider(color:Colors.white24),const SizedBox(height:8),
     Text((member!['full_name']??'Socio Gym Forza').toString(),style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
     Text('Plan: '+(member!['plan_name']??'No disponible').toString(),style:const TextStyle(color:muted)),
     Text('Vigencia hasta: '+(member!['end_date']??'No disponible').toString(),style:const TextStyle(color:muted))]
   ]))),
   const SizedBox(height:10),const Text('GYM FORZA • SISTEMA DE ACCESO',textAlign:TextAlign.center,style:TextStyle(color:muted,fontSize:10))
  ]))));
 }
}
class ApiException implements Exception {const ApiException(this.message,{this.unauthorized=false});final String message;final bool unauthorized;}
class Api {
 static Map<String,dynamic> decode(String body){try{final v=jsonDecode(body);if(v is Map<String,dynamic>)return v;}catch(_){}return <String,dynamic>{};}
 static String msg(Map<String,dynamic>b,String f)=>b['message'] is String&&(b['message'] as String).trim().isNotEmpty?b['message'] as String:f;
 static Future<Map<String,dynamic>> me(String token) async {
  final r=await http.get(Uri.parse(api+'auth/me'),headers:{'Authorization':'Bearer '+token}).timeout(const Duration(seconds:20));final b=decode(r.body);
  if(r.statusCode<200||r.statusCode>=300)throw ApiException(msg(b,'No se pudo verificar tu cuenta en Gym Forza.'),unauthorized:r.statusCode==401);
  if(b['user'] is! Map<String,dynamic>)throw const ApiException('Respuesta de usuario no válida.');return b['user'] as Map<String,dynamic>;
 }
 static Future<Map<String,dynamic>> validate(String token,String qr) async {
  final r=await http.post(Uri.parse(api+'qr/validate'),headers:{'Authorization':'Bearer '+token,'Content-Type':'application/json'},body:jsonEncode({'token':qr})).timeout(const Duration(seconds:20));final b=decode(r.body);
  if(r.statusCode==401)throw const ApiException('Sesión expirada. Inicia sesión nuevamente.',unauthorized:true);
  if(r.statusCode<200||r.statusCode>=300){final f=switch(r.statusCode){403=>'Acceso denegado.',404=>'Código QR no encontrado.',409=>'Este código QR ya fue utilizado.',410=>'El código QR ha expirado.',_=>'No se pudo validar el código (HTTP '+r.statusCode.toString()+').'};throw ApiException(msg(b,f));}
  return b;
 }
}
