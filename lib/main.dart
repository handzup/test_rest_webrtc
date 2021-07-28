import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _renderer = new RTCVideoRenderer();
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:5000'));
  Map<String, dynamic> configuration = {
    "iceServers": [
      {"url": "stun:stun.l.google.com:19302"},
    ]
  };

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };
  void initRTC() async {
    _renderer.initialize();
    final peer = await createPeer();

    //  peer.addTransceiver(kind: RTCRtpMediaType.RTCRtpMediaTypeVideo, init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly));
  }

  Future<RTCPeerConnection> createPeer() async {
    final peer = await createPeerConnection(configuration, _config);

    final offer = await peer.createOffer();
    await peer.setLocalDescription(offer);
    print(offer.sdp);
    print(offer.type);
    final localSdp = await peer.getLocalDescription();
    final result = await _dio.post('/consumer', data: {
      'sdp': {'sdp': localSdp!.sdp, 'type': localSdp.type}
    });
    final sdp = result.data['sdp']['sdp'];
    final type = result.data['sdp']['type'];
    final rmSdp = RTCSessionDescription(sdp, type);
    peer.setRemoteDescription(rmSdp);
    peer.onIceCandidate = (ca) {
      print(ca.candidate);
    };
    peer.onTrack = (track) {
      _renderer.srcObject = track.streams[0];
      setState(() {});
    };
    peer.onAddStream = (st) {
      _renderer.srcObject = st;
      setState(() {});
    };
    return peer;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            const SizedBox(height: 12),
            IconButton(
              onPressed: initRTC,
              icon: Icon(Icons.play_arrow),
              iconSize: 50,
            ),
            const SizedBox(height: 12),
            Container(height: _renderer.videoHeight.toDouble(), width: _renderer.videoWidth.toDouble(), child: RTCVideoView(_renderer)),
          ],
        ),
      );
}
