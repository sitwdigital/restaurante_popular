import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class InternetWrapper extends StatefulWidget {
  final Widget child;

  const InternetWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<InternetWrapper> createState() => _InternetWrapperState();
}

class _InternetWrapperState extends State<InternetWrapper> {
  late StreamSubscription subscription;
  bool hasInternet = true;

  @override
  void initState() {
    super.initState();

    // Monitora mudanças na conectividade
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      if (results.contains(ConnectivityResult.none)) {
        setState(() => hasInternet = false);
        return;
      }

      bool connected = await InternetConnectionChecker().hasConnection;
      setState(() {
        hasInternet = connected;
      });
    });

    _checkConnection();
  }

  Future<void> _checkConnection() async {
    bool connected = await InternetConnectionChecker().hasConnection;
    setState(() {
      hasInternet = connected;
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!hasInternet) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off,
                  size: 100,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Sem conexão com a internet",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Verifique sua conexão para continuar usando o aplicativo.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _checkConnection,
                  child: const Text("Tentar novamente"),
                )
              ],
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}
