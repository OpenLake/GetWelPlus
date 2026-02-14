import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/auth_button.dart';
import 'package:flutter_app/widgets/option_tile.dart';

class StressCheckPage extends StatefulWidget {
  const StressCheckPage({super.key});

  @override
  State<StressCheckPage> createState() => _StressCheckPageState();
}

class _StressCheckPageState extends State<StressCheckPage> {
int selectedOption=0;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stress Check',style: TextStyle(
          fontSize: 27
        ),),
        elevation: 4,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
          child:  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  StyledRadioTile(
                        value: 0,
                        groupValue: selectedOption,
                        title: 'Option 1',
                        onChanged: (value) {
                          setState(() => selectedOption = value!);
                        },
                      ),
                      StyledRadioTile(
                        value: 1,
                        groupValue: selectedOption,
                        title: 'Option 2',
                        onChanged: (value) {
                          setState(() => selectedOption = value!);
                        },
                      ),
                      StyledRadioTile(
                        value: 2,
                        groupValue: selectedOption,
                        title: 'Option 3',
                        onChanged: (value) {
                          setState(() => selectedOption = value!);
                        },
                      ),
                      StyledRadioTile(
                        value: 3,
                        groupValue: selectedOption,
                        title: 'Option 4',
                        onChanged: (value) {
                          setState(() => selectedOption = value!);
                        },
                      ),
                      const SizedBox(height: 20,),

                      Center(child: AuthButton(label: "Next", onPressed: (){}))




                ],
              )

      ),
    );
  }
}
