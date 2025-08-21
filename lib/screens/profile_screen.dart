import '../core/imports.dart';
import 'package:image_picker/image_picker.dart';
import '../model/api_services_company_info.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isLoading = false;
  Uint8List? _logoBytes;

  // Controllers for form fields
  final TextEditingController _legalNameController = TextEditingController();
  final TextEditingController _tradeNameController = TextEditingController();
  final TextEditingController _iceController = TextEditingController();
  final TextEditingController _rcController = TextEditingController();
  final TextEditingController _ifNumberController = TextEditingController();
  final TextEditingController _cnssController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  String _selectedCountry = 'Morocco';
  int? _companyId;
  bool _hadLogo = false; // Track if company had logo initially
  DateTime? _createdAt; // Track creation date

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _tradeNameController.dispose();
    _iceController.dispose();
    _rcController.dispose();
    _ifNumberController.dispose();
    _cnssController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all companies (should be only one)
      final companies = await CompanyInfoService.getAllCompanies();
      
      if (companies.isNotEmpty) {
        // Take the first company (should be the only one)
        final companyData = companies.first;
        _companyId = companyData['CompanyID'];
        
        // Set form data
        _legalNameController.text = companyData['LegalName'] ?? '';
        _tradeNameController.text = companyData['TradeName'] ?? '';
        _iceController.text = companyData['ICE'] ?? '';
        _rcController.text = companyData['RC'] ?? '';
        _ifNumberController.text = companyData['ifNumber'] ?? '';
        _cnssController.text = companyData['CNSS'] ?? '';
        _addressController.text = companyData['Address'] ?? '';
        _cityController.text = companyData['City'] ?? '';
        _phoneController.text = companyData['Phone'] ?? '';
        _emailController.text = companyData['Email'] ?? '';
        _websiteController.text = companyData['Website'] ?? '';
        _selectedCountry = companyData['Country'] ?? 'Morocco';
        
        // Handle creation date
        if (companyData['CreatedAt'] != null) {
          try {
            _createdAt = DateTime.parse(companyData['CreatedAt']);
          } catch (e) {
            _createdAt = null;
          }
        }
        
        // Handle logo - get full company info with logo
        try {
          final fullCompanyData = await CompanyInfoService.getCompanyInfo(_companyId!);
          if (fullCompanyData['logo_base64'] != null) {
            final logoBytes = CompanyInfoService.decodeBase64Logo(fullCompanyData['logo_base64']);
            if (logoBytes != null) {
              setState(() {
                _logoBytes = logoBytes;
                _hadLogo = true;
              });
            }
          }
        } catch (e) {
          // Logo loading failed, continue without logo
          print('Failed to load logo: $e');
        }
      } else {
        // No company exists, show empty form
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل معلومات الشركة: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Show empty form on error
        _clearForm();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _legalNameController.clear();
    _tradeNameController.clear();
    _iceController.clear();
    _rcController.clear();
    _ifNumberController.clear();
    _cnssController.clear();
    _addressController.clear();
    _cityController.clear();
    _phoneController.clear();
    _emailController.clear();
    _websiteController.clear();
    _selectedCountry = 'Morocco';
    setState(() {
      _logoBytes = null;
      _hadLogo = false;
      _createdAt = null;
    });
  }

  Future<void> _saveCompanyInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_companyId != null) {
        // Update existing company
        await CompanyInfoService.updateCompany(
          companyId: _companyId!,
          legalName: _legalNameController.text.trim(),
          tradeName: _tradeNameController.text.trim().isNotEmpty ? _tradeNameController.text.trim() : null,
          ice: _iceController.text.trim(),
          rc: _rcController.text.trim().isNotEmpty ? _rcController.text.trim() : null,
          ifNumber: _ifNumberController.text.trim().isNotEmpty ? _ifNumberController.text.trim() : null,
          cnss: _cnssController.text.trim().isNotEmpty ? _cnssController.text.trim() : null,
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
          city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
          country: _selectedCountry,
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
          logoBytes: _logoBytes,
          removeLogo: _logoBytes == null && _hadLogo, // Remove logo if it was cleared and had logo before
        );
      } else {
        // Create new company
        final result = await CompanyInfoService.createCompany(
          legalName: _legalNameController.text.trim(),
          tradeName: _tradeNameController.text.trim().isNotEmpty ? _tradeNameController.text.trim() : null,
          ice: _iceController.text.trim(),
          rc: _rcController.text.trim().isNotEmpty ? _rcController.text.trim() : null,
          ifNumber: _ifNumberController.text.trim().isNotEmpty ? _ifNumberController.text.trim() : null,
          cnss: _cnssController.text.trim().isNotEmpty ? _cnssController.text.trim() : null,
          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
          city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
          country: _selectedCountry,
          phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
          logoBytes: _logoBytes,
        );
        _companyId = result['CompanyID'];
        
        // Update creation date
        if (result['CreatedAt'] != null) {
          try {
            _createdAt = DateTime.parse(result['CreatedAt']);
          } catch (e) {
            _createdAt = null;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppTranslations.get('profile_updated', Provider.of<LanguageProvider>(context, listen: false).currentLanguage)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ معلومات الشركة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        
        if (mounted) {
          setState(() {
            _logoBytes = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerDialog() {
    final currentLang = Provider.of<LanguageProvider>(context, listen: false).currentLanguage;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.get('select_image', currentLang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppTranslations.get('camera', currentLang)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppTranslations.get('gallery', currentLang)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final currentLang = languageProvider.currentLanguage;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(AppTranslations.get('company_profile', currentLang)),
            backgroundColor: const Color(0xFF1E40AF),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
            ],
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF1E40AF),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header Section
                      _buildHeader(currentLang),

                      // Content Section
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Logo Section
                                  _buildLogoSection(currentLang),

                                  const SizedBox(height: 30),

                                  // Company Details Section
                                  _buildCompanyDetailsSection(currentLang),

                                  const SizedBox(height: 30),

                                  // Contact Information Section
                                  _buildContactInfoSection(currentLang),

                                  const SizedBox(height: 30),

                                  // Legal Information Section
                                  _buildLegalInfoSection(currentLang),

                                  const SizedBox(height: 40),

                                  // Action Buttons
                                  if (_isEditing) _buildActionButtons(currentLang),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeader(String currentLang) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        children: [
          Text(
            AppTranslations.get('company_info', currentLang),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppTranslations.get('created_at', currentLang)}: ${_formatDate(_createdAt)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(String currentLang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            AppTranslations.get('company_logo', currentLang),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          
          // Logo Display
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _logoBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _logoBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.business,
                          size: 60,
                          color: Color(0xFF1E40AF),
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.business,
                    size: 60,
                    color: Color(0xFF1E40AF),
                  ),
          ),
          
          const SizedBox(height: 20),
          
          if (_isEditing) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _showImagePickerDialog,
                  icon: const Icon(Icons.upload, size: 18),
                  label: Text(AppTranslations.get('upload_logo', currentLang)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (_logoBytes != null || _hadLogo)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _logoBytes = null;
                      });
                    },
                    icon: const Icon(Icons.delete, size: 18),
                    label: Text(AppTranslations.get('remove_logo', currentLang)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompanyDetailsSection(String currentLang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.get('company_details', currentLang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Legal Name
          _buildTextField(
            controller: _legalNameController,
            label: AppTranslations.get('legal_name', currentLang),
            icon: Icons.business,
            isRequired: true,
            enabled: _isEditing,
          ),
          
          const SizedBox(height: 16),
          
          // Trade Name
          _buildTextField(
            controller: _tradeNameController,
            label: AppTranslations.get('trade_name', currentLang),
            icon: Icons.store,
            enabled: _isEditing,
          ),
          
          const SizedBox(height: 16),
          
          // Address
          _buildTextField(
            controller: _addressController,
            label: AppTranslations.get('address', currentLang),
            icon: Icons.location_on,
            enabled: _isEditing,
            maxLines: 2,
          ),
          
          const SizedBox(height: 16),
          
          // City and Country Row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cityController,
                  label: AppTranslations.get('city', currentLang),
                  icon: Icons.location_city,
                  enabled: _isEditing,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  value: _selectedCountry,
                  label: AppTranslations.get('country', currentLang),
                  icon: Icons.public,
                  enabled: _isEditing,
                  items: ['Morocco', 'Algeria', 'Tunisia', 'Egypt', 'Saudi Arabia'],
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection(String currentLang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.contact_phone,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.get('contact_info', currentLang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Phone
          _buildTextField(
            controller: _phoneController,
            label: AppTranslations.get('phone', currentLang),
            icon: Icons.phone,
            enabled: _isEditing,
            keyboardType: TextInputType.phone,
          ),
          
          const SizedBox(height: 16),
          
          // Email
          _buildTextField(
            controller: _emailController,
            label: AppTranslations.get('email', currentLang),
            icon: Icons.email,
            enabled: _isEditing,
            keyboardType: TextInputType.emailAddress,
          ),
          
          const SizedBox(height: 16),
          
          // Website
          _buildTextField(
            controller: _websiteController,
            label: AppTranslations.get('website', currentLang),
            icon: Icons.language,
            enabled: _isEditing,
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalInfoSection(String currentLang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.gavel,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppTranslations.get('legal_info', currentLang),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // ICE Number
          _buildTextField(
            controller: _iceController,
            label: AppTranslations.get('ice_number', currentLang),
            icon: Icons.numbers,
            enabled: _isEditing,
            isRequired: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppTranslations.get('required', Provider.of<LanguageProvider>(context, listen: false).currentLanguage);
              }
              if (value.length != 15 || !RegExp(r'^\d{15}$').hasMatch(value)) {
                return 'رقم ICE يجب أن يكون 15 رقم';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // RC Number
          _buildTextField(
            controller: _rcController,
            label: AppTranslations.get('rc_number', currentLang),
            icon: Icons.description,
            enabled: _isEditing,
          ),
          
          const SizedBox(height: 16),
          
          // IF Number
          _buildTextField(
            controller: _ifNumberController,
            label: AppTranslations.get('if_number', currentLang),
            icon: Icons.receipt,
            enabled: _isEditing,
          ),
          
          const SizedBox(height: 16),
          
          // CNSS Number
          _buildTextField(
            controller: _cnssController,
            label: AppTranslations.get('cnss_number', currentLang),
            icon: Icons.security,
            enabled: _isEditing,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator ?? (isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return AppTranslations.get('required', Provider.of<LanguageProvider>(context, listen: false).currentLanguage);
              }
              return null;
            }
          : null),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required bool enabled,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildActionButtons(String currentLang) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () {
              setState(() {
                _isEditing = false;
              });
              // Reload data to reset any changes
              _loadCompanyInfo();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(AppTranslations.get('cancel', currentLang)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveCompanyInfo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(AppTranslations.get('save_changes', currentLang)),
          ),
        ),
      ],
    );
  }
}
