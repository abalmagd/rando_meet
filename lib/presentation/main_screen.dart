import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _localVideoRenderer = RTCVideoRenderer();
  final _remoteVideoRenderer = RTCVideoRenderer();

  bool _offer = false;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  @override
  void initState() {
    super.initState();
    _localVideoRenderer.initialize();
    getUserMedia();
    _createPeerConnection();
  }

  @override
  void dispose() {
    _localVideoRenderer.dispose();
    super.dispose();
  }

  Future<MediaStream> getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {'facingMode': 'user'},
    };

    MediaStream stream =
        await navigator.mediaDevices.getUserMedia(mediaConstraints);

    _localVideoRenderer.srcObject = stream;

    return stream;
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      'iceServers': [
        /*{'url': 'stun:stun.l.google.com:19302'},*/
        {
          'url': 'turn:turn.i2-host.com:3478',
          'username': 'saritest',
          'credential': 'test546321',
        }
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    _localStream = await getUserMedia();

    RTCPeerConnection pc =
        await createPeerConnection(configuration, offerSdpConstraints);

    if (_localStream == null) {
      debugPrint('Local stream is null');
    }

    pc.addStream(_localStream!);

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        debugPrint(json.encode({
          'candidate': e.candidate,
          'sdpMid': e.sdpMid,
          'sdpMlineIndex': e.sdpMLineIndex
        }));
      }
    };

    pc.onIceConnectionState = (e) {
      debugPrint(e.toString());
    };

    pc.onAddStream = (stream) {
      debugPrint('addStream: ${stream.id}');
      _remoteVideoRenderer.srcObject = stream;
    };

    return pc;
  }

  void _createOffer() async {
    RTCSessionDescription description =
        await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
    var session = description.sdp.toString();
    debugPrint(json.encode(session));
    _offer = true;

    _peerConnection!.setLocalDescription(description);
  }

  void _createAnswer() async {
    RTCSessionDescription description =
        await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});

    var session = description.sdp.toString();
    debugPrint(json.encode(session));

    _peerConnection!.setLocalDescription(description);
  }

  void _setRemoteDescription() async {
    String sdp = 'Test run';

    RTCSessionDescription description =
        RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
    debugPrint(description.toMap());

    await _peerConnection!.setRemoteDescription(description);
  }

  void _addCandidate() async {
    String jsonString = 'Test Run';
    dynamic session = await jsonDecode(jsonString);
    debugPrint(session['candidate']);
    dynamic candidate = RTCIceCandidate(
        session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
    await _peerConnection!.addCandidate(candidate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rando Meet')),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.green.withOpacity(0.3),
            child: RTCVideoView(
              _remoteVideoRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
          Positioned(
            top: 25,
            right: 25,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 225,
                width: 150,
                child: RTCVideoView(
                  _localVideoRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
