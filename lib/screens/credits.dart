import 'package:flutter/material.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

@immutable
class TeamMember {
  const TeamMember({
    required this.name,
    required this.usn,
    required this.email,
    required this.portrait,
  });

  final String name;
  final String usn;
  final String email;
  final String portrait;
}

const teamMembers = <TeamMember>[
  TeamMember(
    name: 'DEVIDAS',
    usn: '1HK23CS041',
    email: '1hk23cs041@hkbk.edu.in',
    portrait: 'assets/images/credits/devidas.png',
  ),
  TeamMember(
    name: 'HARSHA BM',
    usn: '1HK23CS051',
    email: '1hk23cs051@hkbk.edu.in',
    portrait: 'assets/images/credits/harsha-bm.png',
  ),
  TeamMember(
    name: 'PAVAN KALYAN',
    usn: '1HK23CS056',
    email: '1hk23cs056@hkbk.edu.in',
    portrait: 'assets/images/credits/pavan-kalyan.png',
  ),
  TeamMember(
    name: 'GOVIND RAJ',
    usn: '1HK23CS049',
    email: '1hk23cs049@hkbk.edu.in',
    portrait: 'assets/images/credits/govind-raj.png',
  ),
];

class StudentCreditsScreen extends StatelessWidget {
  const StudentCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      flexibleSpace: const ScenicAppBarBackground(),
      title: const Text('Student Credits'),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        const _ProjectIntroduction(),
        const SectionLabel('Our Team'),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 560 ? 3 : 2;
            return GridView.builder(
              itemCount: teamMembers.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 228,
              ),
              itemBuilder: (context, index) =>
                  TeamMemberCard(member: teamMembers[index]),
            );
          },
        ),
        const SectionLabel('Our Guide'),
        const GuideProfileCard(),
      ],
    ),
  );
}

class _ProjectIntroduction extends StatelessWidget {
  const _ProjectIntroduction();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF7FBFD),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: line),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: paleBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.school_outlined, color: accentBlue, size: 23),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Raitha Mitra is an independent student project created to make Karnataka market information and crop planning tools easier to access.',
            style: TextStyle(fontSize: 13, height: 1.5, color: ink),
          ),
        ),
      ],
    ),
  );
}

class TeamMemberCard extends StatelessWidget {
  const TeamMemberCard({super.key, required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 1,
    shadowColor: const Color(0x14183B5B),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: const BorderSide(color: line),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 116,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: ColoredBox(
                color: const Color(0xFFF4F8FA),
                child: Image.asset(
                  member.portrait,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            member.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            member.usn,
            style: const TextStyle(fontSize: 10, color: blueMuted),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                member.email,
                maxLines: 2,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  fontSize: 10.5,
                  height: 1.2,
                  color: blueText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6EF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Team Member',
              maxLines: 1,
              style: TextStyle(
                fontSize: 9,
                height: 1.1,
                color: Color(0xFF427553),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class GuideProfileCard extends StatelessWidget {
  const GuideProfileCard({super.key});

  @override
  Widget build(BuildContext context) => Card(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: line),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 76,
              height: 76,
              color: paleBlue,
              child: const Icon(
                Icons.person_outline,
                size: 38,
                color: blueMuted,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prof. Khallikkunaisa Mam',
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Project Guide',
                  style: TextStyle(
                    color: Color(0xFF427553),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'HKBK College of Engineering',
                  style: TextStyle(color: blueMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
