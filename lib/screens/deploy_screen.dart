import 'package:flutter/material.dart';
import '../services/deploy/one_click_deploy.dart';

class DeployScreen extends StatefulWidget {
  final String projectId;
  
  DeployScreen({required this.projectId});

  @override
  _DeployScreenState createState() => _DeployScreenState();
}

class _DeployScreenState extends State<<DeployScreen> {
  bool _isDeploying = false;
  String? _deployUrl;
  String? _error;
  String _selectedPlatform = 'netlify';

  final _netlifyTokenController = TextEditingController();
  final _vercelTokenController = TextEditingController();
  final _siteNameController = TextEditingController();

  Future<void> _deploy() async {
    setState(() {
      _isDeploying = true;
      _deployUrl = null;
      _error = null;
    });

    Map<String, dynamic> result;

    switch (_selectedPlatform) {
      case 'netlify':
        result = await OneClickDeploy.instance.deployToNetlify(
          projectId: widget.projectId,
          siteName: _siteNameController.text,
          buildDir: '/path/to/build/web',
          netlifyToken: _netlifyTokenController.text,
        );
        break;
      case 'vercel':
        result = await OneClickDeploy.instance.deployToVercel(
          projectId: widget.projectId,
          buildDir: '/path/to/build/web',
          vercelToken: _vercelTokenController.text,
        );
        break;
      default:
        result = {'success': false, 'error': 'Unknown platform'};
    }

    setState(() {
      _isDeploying = false;
      if (result['success'] == true) {
        _deployUrl = result['url'];
      } else {
        _error = result['error'].toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('One-Click Deploy')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deploy Platform:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'netlify', label: Text('Netlify')),
                ButtonSegment(value: 'vercel', label: Text('Vercel')),
                ButtonSegment(value: 'vps', label: Text('VPS')),
              ],
              selected: {_selectedPlatform},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedPlatform = newSelection.first;
                });
              },
            ),
            SizedBox(height: 24),
            if (_selectedPlatform == 'netlify') ...[
              TextField(
                controller: _siteNameController,
                decoration: InputDecoration(
                  labelText: 'Site Name',
                  hintText: 'my-kitsune-app',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _netlifyTokenController,
                decoration: InputDecoration(
                  labelText: 'Netlify Token',
                  hintText: 'np_XXXXXXXXXXXXX',
                ),
                obscureText: true,
              ),
            ],
            if (_selectedPlatform == 'vercel') ...[
              TextField(
                controller: _vercelTokenController,
                decoration: InputDecoration(
                  labelText: 'Vercel Token',
                  hintText: 'vercel_token_here',
                ),
                obscureText: true,
              ),
            ],
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDeploying ? null : _deploy,
                icon: _isDeploying 
                  ? SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : Icon(Icons.rocket_launch),
                label: Text(_isDeploying ? 'Deploying...' : 'Deploy Now'),
              ),
            ),
            SizedBox(height: 24),
            if (_deployUrl != null) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎉 Deployed Successfully!', 
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    SelectableText(_deployUrl!, style: TextStyle(color: Colors.blue)),
                    SizedBox(height: 8),
                    Text('Your app is live!', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Error: $_error', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
