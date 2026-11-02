import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phonecontroller = TextEditingController();
  final agecontroller = TextEditingController();
  final citycontroller = TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;

  bool isSignUp = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phonecontroller.dispose();
    agecontroller.dispose();
    citycontroller.dispose();
    super.dispose();
  }

  // Sign Up
  Future<void> signUp(String email, String password) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      await user.updateDisplayName(
        nameController.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': nameController.text.trim(),
        'email': email.trim(),
        'phone': phonecontroller.text.trim(),
        'age': int.parse(agecontroller.text.trim()),
        'city': citycontroller.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Signup successful!');
      print('User UID: ${user.uid}');

      if (!mounted) return;

      setState(() {
        nameController.clear();
        emailController.clear();
        passwordController.clear();
        confirmPasswordController.clear();
        phonecontroller.clear();
        agecontroller.clear();
        citycontroller.clear();
        isSignUp = false;
      });

      formKey.currentState?.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Signup successful! Please sign in.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      print(e.code);
      print(e.message);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Signup failed'),
        ),
      );
    }
  }

  // Sign In
  Future<void> signIn(String email, String password) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Login successful!');
      print(credential.user?.email);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(
            name: credential.user?.displayName ?? 'User',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      print(e.code);
      print(e.message);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Login failed'),
        ),
      );
    }
  }

  // Validate and submit
  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (isSignUp) {
        await signUp(
          emailController.text.trim(),
          passwordController.text,
        );
      } else {
        await signIn(
          emailController.text.trim(),
          passwordController.text,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isSignUp ? 'Create Account' : 'Welcome Back',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // Sign Up / Sign In toggle
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Sign Up'),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Sign In'),
                    ),
                  ],
                  selected: {isSignUp},
                  onSelectionChanged: (value) {
                    setState(() {
                      isSignUp = value.first;
                      formKey.currentState?.reset();
                    });
                  },
                ),

                const SizedBox(height: 20),

                // SIGN UP ONLY FIELDS
                if (isSignUp) ...[
                  // Name
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }

                      if (value.trim().length < 2) {
                        return 'Name must have at least 2 characters';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // Phone
                  TextFormField(
                    controller: phonecontroller,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // Age
                  TextFormField(
                    controller: agecontroller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(Icons.cake),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your age';
                      }

                      final age = int.tryParse(value.trim());

                      if (age == null || age < 1 || age > 120) {
                        return 'Please enter a valid age';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  // City
                  TextFormField(
                    controller: citycontroller,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your city';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 15),
                ],

                // EMAIL - BOTH SIGN UP AND SIGN IN
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }

                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value.trim())) {
                      return 'Please enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // PASSWORD - BOTH SIGN UP AND SIGN IN
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }

                    if (isSignUp && value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }

                    return null;
                  },
                ),

                // CONFIRM PASSWORD - SIGN UP ONLY
                if (isSignUp) ...[
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }

                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }

                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 20),

                // BUTTON
                ElevatedButton(
                  onPressed: isLoading ? null : submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isSignUp ? 'Create Account' : 'Sign In',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}