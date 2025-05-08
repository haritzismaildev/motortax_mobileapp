import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MotortaxMobileApp());
}

class MotortaxMobileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pajak Kendaraan Mobile Apps',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

enum TabOption { register, list }

class _HomePageState extends State<HomePage> {
  TabOption _selectedTab = TabOption.register;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pajak Kendaraan')),
      body:
          _selectedTab == TabOption.register
              ? RegisterPage(
                onSuccess: () {
                  // Jika registrasi sukses, alihkan ke tab daftar kendaraan
                  setState(() {
                    _selectedTab = TabOption.list;
                  });
                },
              )
              : VehicleListPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab == TabOption.register ? 0 : 1,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.app_registration),
            label: 'Registrasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Daftar Kendaraan',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedTab = (index == 0) ? TabOption.register : TabOption.list;
          });
        },
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  final VoidCallback? onSuccess;
  RegisterPage({this.onSuccess});
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController ownerIdController = TextEditingController();
  TextEditingController regNumberController = TextEditingController();
  TextEditingController vehicleTypeController = TextEditingController();
  TextEditingController manufactureYearController = TextEditingController();

  bool isLoading = false;
  String resultMessage = '';

  // Ganti URL di bawah sesuai alamat backend kamu.
  final String baseUrl = 'http://192.168.x.x:3000';

  Future<void> registerVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      resultMessage = '';
    });

    final url = Uri.parse('$baseUrl/api/vehicles/register');
    final body = {
      'ownerId': ownerIdController.text,
      'registrationNumber': regNumberController.text,
      'vehicleType': vehicleTypeController.text,
      'manufactureYear': manufactureYearController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      setState(() {
        resultMessage =
            response.statusCode == 201
                ? 'Pendaftaran berhasil: ${data['vehicle']}'
                : 'Error: ${data['error']}';
      });

      if (response.statusCode == 201 && widget.onSuccess != null) {
        widget.onSuccess!();
      }
    } catch (e) {
      setState(() {
        resultMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    ownerIdController.dispose();
    regNumberController.dispose();
    vehicleTypeController.dispose();
    manufactureYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text('Form Registrasi Kendaraan', style: TextStyle(fontSize: 20)),
          SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: ownerIdController,
                  decoration: InputDecoration(
                    labelText: 'Owner ID',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) => value!.isEmpty ? 'Owner ID wajib diisi' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: regNumberController,
                  decoration: InputDecoration(
                    labelText: 'Nomor Registrasi',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? 'Nomor Registrasi wajib diisi'
                              : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: vehicleTypeController,
                  decoration: InputDecoration(
                    labelText: 'Jenis Kendaraan',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Jenis Kendaraan wajib diisi' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: manufactureYearController,
                  decoration: InputDecoration(
                    labelText: 'Tahun Pembuatan',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Tahun Pembuatan wajib diisi' : null,
                ),
                SizedBox(height: 16),
                isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: registerVehicle,
                      child: Text('Daftar Kendaraan'),
                    ),
              ],
            ),
          ),
          SizedBox(height: 16),
          if (resultMessage.isNotEmpty)
            Text(resultMessage, style: TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }
}

class VehicleListPage extends StatefulWidget {
  @override
  _VehicleListPageState createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
  // final String baseUrl = 'http://172.26.64.1:1981'; // Ganti sesuai alamat backend lokal
  final String baseUrl = 'https://e962-103-47-133-152.ngrok-free.app';
  List vehicles = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse('$baseUrl/api/vehicles');
    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      setState(() {
        vehicles = data['vehicles'];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching vehicles: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fungsi untuk menghitung pajak kendaraan
  Future<void> calculateTax(int vehicleId) async {
    final url = Uri.parse('$baseUrl/api/vehicles/$vehicleId/calculate-tax');
    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text('Perhitungan Pajak'),
              content: Text(
                'Kendaraan ID: ${data['vehicleId']}\nNomor Registrasi: ${data['registrationNumber']}\nPajak Dasar: Rp${data['baseTax']}\nSurcharge: Rp${data['surcharge']}\nTotal Pajak: Rp${data['totalTax']}',
              ),
              actions: [
                TextButton(
                  child: Text('Tutup'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error calculating tax: $e')));
    }
  }

  // Fungsi untuk melakukan simulasi pembayaran pajak
  Future<void> payTax(int vehicleId) async {
    TextEditingController paymentController = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Pembayaran Pajak'),
            content: TextField(
              controller: paymentController,
              decoration: InputDecoration(
                labelText: 'Metode Pembayaran (misal: Debit)',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Kirim'),
              ),
            ],
          ),
    );

    if (paymentController.text.isEmpty) return; // Jika batal

    final url = Uri.parse('$baseUrl/api/vehicles/$vehicleId/paytax');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'paymentMethod': paymentController.text.trim()}),
      );
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pembayaran berhasil! ID Transaksi: ${data['transaction']['transactionId']}',
          ),
        ),
      );
      // Refresh list agar transaksi terlihat
      fetchVehicles();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error processing payment: $e')));
    }
  }

  Widget buildVehicleItem(dynamic vehicle) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: ListTile(
        title: Text(
          '${vehicle['registrationNumber']} - ${vehicle['vehicleType']}',
        ),
        subtitle: Text('Tahun: ${vehicle['manufactureYear']}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'hitung') {
              calculateTax(vehicle['id']);
            } else if (value == 'bayar') {
              payTax(vehicle['id']);
            }
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(value: 'hitung', child: Text('Hitung Pajak')),
                PopupMenuItem(value: 'bayar', child: Text('Bayar Pajak')),
              ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchVehicles,
      child:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  return buildVehicleItem(vehicles[index]);
                },
              ),
    );
  }
}
