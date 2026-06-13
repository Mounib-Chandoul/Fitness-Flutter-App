import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness/config.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> users = [];
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchUsers();
  }

  Future<void> _loadTokenAndFetchUsers() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('jwt_token');
    if (token != null) {
      await _fetchUsers();
    } else {
      // Handle no token
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUsers() async {
    final response = await http.get(
      Uri.parse('${Config.apiBaseUrl}/admin/users'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        users = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      // Handle error
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load users')));
      }
    }
  }

  Future<void> _deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('${Config.apiBaseUrl}/admin/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        users.removeWhere((user) => user['id'] == userId);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('User deleted')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete user')));
    }
  }

  Future<void> _changeRole(int userId, String newRole) async {
    final response = await http.patch(
      Uri.parse('${Config.apiBaseUrl}/admin/users/$userId/role'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'new_role': newRole}),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        final user = users.firstWhere((u) => u['id'] == userId);
        user['role'] = newRole;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Role updated')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update role')));
    }
  }

  void _showChangeRoleDialog(int userId, String currentRole) {
    String selectedRole = currentRole;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['client', 'coach', 'admin']
                .map(
                  (role) => RadioListTile<String>(
                    title: Text(role),
                    value: role,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _changeRole(userId, selectedRole);
                Navigator.of(context).pop();
              },
              child: Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Management')),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text('Admin Menu')),
            ListTile(
              title: Text('Home'),
              onTap: () {
                // Navigate to home
              },
            ),
            // Add more items
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: users
                    .map(
                      (user) => DataRow(
                        cells: [
                          DataCell(Text(user['id'].toString())),
                          DataCell(Text(user['email'])),
                          DataCell(Text(user['name'])),
                          DataCell(Text(user['role'])),
                          DataCell(
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _deleteUser(user['id']),
                                  child: Text('Delete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _showChangeRoleDialog(
                                    user['id'],
                                    user['role'],
                                  ),
                                  child: Text('Change Role'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}
