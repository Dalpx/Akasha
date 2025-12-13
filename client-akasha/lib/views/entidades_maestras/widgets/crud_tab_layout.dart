import 'package:flutter/material.dart';

class CrudTabLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onAdd;
  final Widget child;

  const CrudTabLayout({
    super.key,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onAdd,
    required this.child,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(subtitle),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: Icon(buttonIcon),
                label: Text(buttonLabel),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
