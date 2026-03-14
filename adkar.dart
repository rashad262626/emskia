import 'package:flutter/material.dart';
import 'bt.dart'; // Rashad BottomNavigationBar

class AdkarPage extends StatelessWidget {
  const AdkarPage({super.key});

  // ✅ Intro text (added manually)
  static const String introText =
      "أمر الله سبحانه وتعالى عباده المؤمنين بلزوم الذكر، والمداومة عليه في كلّ حينٍ وآن، "
      "فقال جلَّ وعلا: {يا أيها الذين آمنوا اذكروا الله ذكرا كثيرا * وسبحوه بكرة وأصيلا} (الأحزاب:41-42)، "
      "وقال سبحانه: {فسبحان الله حين تمسون وحين تصبحون * وله الحمد في السماوات والأرض وعشيا وحين تظهرون} (الروم:17-18).\n\n"
      "وفيما يلي مجموعة من الأذكار الثابتة، التي تُقال في الصباح وفي المساء:";

  // ✅ Manual sections (Morning / Evening / Sleep)
  static final List<Map<String, dynamic>> sections = [
    {
      "title": "أذكار الصباح",
      "items": [
        {
          "text":
          "قراءة آية الكرسي:\n"
              "{الله لا إله إلا هو الحي القيوم لا تأخذه سنة ولا نوم له ما في السماوات وما في الأرض "
              "من ذا الذي يشفع عنده إلا بإذنه يعلم ما بين أيديهم وما خلفهم ولا يحيطون بشيء من علمه "
              "إلا بما شاء وسع كرسيه السماوات والأرض ولا يؤده حفظهما وهو العلي العظيم} (البقرة:255)",
          "count": 1,
          "ref": "رواه الحاكم وابن حبان",
          "hint": null,
        },
        {
          "text":
          "أصبحنا على فطرة الإسلام وكلِمة الإخلاص، ودين نبينا محمد صلى الله عليه وسلم، "
              "ومِلَّةِ أبينا إبراهيم، حنيفاً مسلماً، وما كان من المشركين.",
          "count": 1,
          "ref": "رواه أحمد",
          "hint": null,
        },
        {
          "text": "رضيت بالله ربا، وبالإسلام دينا، وبمحمد صلى الله عليه وسلم نبياً.",
          "count": 1,
          "ref": "رواه أصحاب السنن",
          "hint": null,
        },
        {
          "text": "اللهم إني أسألك علماً نافعاً، ورزقاً طيباً، وعملاً متقبلاً.",
          "count": 1,
          "ref": "رواه ابن ماجه",
          "hint": null,
        },
        {
          "text": "اللهم بك أصبحنا، وبك أمسينا، وبك نحيا، وبك نموت، وإليك النشور.",
          "count": 1,
          "ref": "رواه أصحاب السنن عدا النسائي",
          "hint": null,
        },
        {
          "text":
          "لا إله إلا الله وحده، لا شريك له، له الملك، وله الحمد، وهو على كل شيء قدير.",
          "count": 1,
          "ref": "رواه البزار والطبراني في \"الدعاء\"",
          "hint": null,
        },
        {
          "text":
          "يا حيُّ يا قيوم برحمتك أستغيثُ، أصلح لي شأني كله، ولا تَكلني إلى نفسي طَرْفَةَ عين أبدًا.",
          "count": 1,
          "ref": "رواه البزار",
          "hint": null,
        },
        {
          "text":
          "اللهم أنت ربي، لا إله إلا أنت، خلقتني وأنا عبدُك, وأنا على عهدِك ووعدِك ما استطعتُ، "
              "أعوذ بك من شر ما صنعتُ، أبوءُ لَكَ بنعمتكَ عَلَيَّ، وأبوء بذنبي، فاغفر لي، فإنه لا يغفرُ الذنوب إلا أنت.",
          "count": 1,
          "ref": "رواه البخاري",
          "hint": null,
        },
        {
          "text":
          "اللهم فاطر السموات والأرض، عالم الغيب والشهادة، رب كل شيء ومليكه، "
              "أشهد أن لا إله إلا أنت, أعوذ بك من شرّ نفسي، ومن شرّ الشيطان وشركه، "
              "وأن أقترف على نفسي سوءا، أو أجره إلى مسلم.",
          "count": 1,
          "ref": "رواه الترمذي",
          "hint": null,
        },
        {
          "text":
          "أصبحنا وأصبح الملك لله، والحمد لله ولا إله إلا الله وحده لا شريك له، له الملك وله الحمد، "
              "وهو على كل شيء قدير، أسألك خير ما في هذا اليوم، وخير ما بعده، وأعوذ بك من شر هذا اليوم، "
              "وشر ما بعده، وأعوذ بك من الكسل وسوء الكبر، وأعوذ بك من عذاب النار وعذاب القبر.",
          "count": 1,
          "ref": "رواه مسلم",
          "hint": null,
        },
        {
          "text":
          "اللهم إني أسألك العفو والعافية في الدنيا والآخرة، اللهم أسألك العفو والعافية في ديني ودنياي وأهلي ومالي، "
              "اللهم استر عوراتي، وآمن روعاتي، واحفظني من بين يدي، ومن خلفي، وعن يميني، وعن شمالي، "
              "ومن فوقي، وأعوذ بك أن أغتال من تحتي.",
          "count": 1,
          "ref": "رواه أبو داود وابن ماجه",
          "hint": null,
        },
        {
          "text":
          "بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء، وهو السميع العليم.",
          "count": 3,
          "ref": "رواه أصحاب السنن عدا النسائي",
          "hint": "تقال ثلاث مرات",
        },
        {
          "text":
          "سبحان الله عدد خلقه، سبحان الله رضا نفسه، سبحان الله زنة عرشه، سبحان الله مداد كلماته.",
          "count": 3,
          "ref": "رواه مسلم",
          "hint": "تقال ثلاث مرات",
        },
        {
          "text":
          "اللهم عافني في بدني، اللهم عافني في سمعي، اللهم عافني في بصري، لا إله إلا أنت، "
              "اللهم إني أعوذ بك من الكفر والفقر، اللهم إني أعوذ بك من عذاب القبر، لا إله إلا أنت.",
          "count": 3,
          "ref": "رواه أبو داود",
          "hint": "تقال ثلاث مرات",
        },
        {
          "text": "قراءة سور: الإخلاص، والفلق، والناس.",
          "count": 3,
          "ref": "رواه الترمذي",
          "hint": "كل سورة ثلاث مرات",
        },
        {
          "text":
          "{حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم} (التوبة:129).",
          "count": 7,
          "ref": "رواه أبو داود",
          "hint": "تقال سبع مرات",
        },
        {
          "text":
          "اللهم إني أصبحت، أُشهدك وأُشهد حملة عرشك وملائكتك وجميع خلقك أنك أنت الله، "
              "وحدك لا شريك لك وأن محمداً عبدك ورسولك.",
          "count": 4,
          "ref": "أبو داود والترمذي",
          "hint": "تقال أربع مرات",
        },
        {
          "text":
          "لا إله إلا الله وحده، لا شريك له، له الملك، وله الحمد، يحيي ويميت، وهو على كل شيء قدير.",
          "count": 10,
          "ref": "رواه ابن حبان",
          "hint": "تقال عشر مرات",
        },
        {
          "text": "سبحان الله وبحمده. أو: سبحان الله العظيم وبحمده.",
          "count": 100,
          "ref": "رواه مسلم",
          "hint": "مائة مرة أو أكثر",
        },
        {
          "text": "أستغفر الله.",
          "count": 100,
          "ref": "رواه ابن أبي شيبة",
          "hint": "مائة مرة",
        },
        {
          "text":
          "سبحان الله، والحمد لله، والله أكبر, لا إله إلا الله وحده، لا شريك له، له الملك، وله الحمد، "
              "وهو على كل شيء قدير.",
          "count": 100,
          "ref": "رواه الترمذي",
          "hint": "مائة مرة أو أكثر",
        },
      ],
    },

    {
      "title": "أذكار المساء",
      "items": [
        {
          "text":
          "قراءة آية الكرسي:\n"
              "{الله لا إله إلا هو الحي القيوم لا تأخذه سنة ولا نوم...} (البقرة:255)",
          "count": 1,
          "ref": "رواه الحاكم وابن حبان",
          "hint": null,
        },
        {
          "text":
          "أمسينا على فطرة الإسلام وكلِمة الإخلاص، ودين نبينا محمد صلى الله عليه وسلم، "
              "ومِلَّةِ أبينا إبراهيم، حنيفاً مسلماً، وما كان من المشركين.",
          "count": 1,
          "ref": "رواه أحمد",
          "hint": null,
        },
        {
          "text": "رضيت بالله ربا، وبالإسلام دينا، وبمحمد صلى الله عليه وسلم نبياً.",
          "count": 1,
          "ref": "رواه أصحاب السنن",
          "hint": null,
        },
        {
          "text": "اللهم بك أمسينا، وبك أصبحنا، وبك نحيا، وبك نموت، وإليك المصير.",
          "count": 1,
          "ref": "رواه أصحاب السنن عدا النسائي",
          "hint": null,
        },
        {
          "text":
          "بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء، وهو السميع العليم.",
          "count": 3,
          "ref": "رواه أصحاب السنن عدا النسائي",
          "hint": "تقال ثلاث مرات",
        },
        {
          "text": "أعوذ بكلمات الله التامَّات من شر ما خلق.",
          "count": 3,
          "ref": "رواه مسلم",
          "hint": "تقال ثلاث مرات",
        },
        {
          "text": "قراءة سور: الإخلاص، والفلق، والناس.",
          "count": 3,
          "ref": "رواه الترمذي",
          "hint": "كل سورة ثلاث مرات",
        },
        {
          "text":
          "{حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم} (التوبة:129).",
          "count": 7,
          "ref": "رواه أبو داود",
          "hint": "تقال سبع مرات",
        },
        {
          "text": "سبحان الله وبحمده. أو: سبحان الله العظيم وبحمده.",
          "count": 100,
          "ref": "رواه مسلم",
          "hint": "مائة مرة أو أكثر",
        },
        {
          "text": "أستغفر الله.",
          "count": 100,
          "ref": "رواه ابن أبي شيبة",
          "hint": "مائة مرة",
        },
      ],
    },

    {
      "title": "أذكار النوم - حصن المسلم",
      "items": [
        {
          "text":
          "قُلۡ هُوَ ٱللَّهُ أَحَدٌ ١ ٱللَّهُ ٱلصَّمَدُ ٢ لَمۡ يَلِدۡ وَلَمۡ يُولَدۡ ٣ وَلَمۡ يَكُن لَّهُۥ كُفُوًا أَحَدُۢ ٤",
          "count": 3,
          "ref": "البخاري ومسلم",
          "hint": "يجمع كفيه ثم ينفث فيهما فيقرأ فيهما",
        },
        {
          "text":
          "ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ ٱلۡحَيُّ ٱلۡقَيُّومُ... ٢٥٥",
          "count": 1,
          "ref": "البخاري",
          "hint":
          "من قرأها إذا أوى إلى فراشه فإنه لن يزال عليه من اللَّه حافظ ولا يقربه شيطان حتى يصبح",
        },
        {
          "text":
          "ءَامَنَ ٱلرَّسُولُ بِمَآ أُنزِلَ إِلَيۡهِ... ٢٨٥-٢٨٦",
          "count": 1,
          "ref": "البخاري ومسلم",
          "hint": "من قرأهما في ليلة كفتاه",
        },
        {
          "text":
          "بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ...",
          "count": 1,
          "ref": "البخاري ومسلم",
          "hint": null,
        },
        {
          "text":
          "اللَّهُمَّ إِنَّكَ خَلَقْتَ نَفْسِي وَأَنْتَ تَوَفَّاهَا...",
          "count": 1,
          "ref": "مسلم",
          "hint": null,
        },
        {
          "text":
          "اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ",
          "count": 1,
          "ref": "أبو داود والترمذي",
          "hint": null,
        },
        {
          "text": "بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا",
          "count": 1,
          "ref": "البخاري ومسلم",
          "hint": null,
        },
        {
          "text": "سُبْحَانَ اللَّهِ",
          "count": 33,
          "ref": "البخاري ومسلم",
          "hint": "خيراً له من خادم",
        },
        {
          "text": "الْحَمْدُ لِلَّهِ",
          "count": 33,
          "ref": "البخاري ومسلم",
          "hint": "خيراً له من خادم",
        },
        {
          "text": "اللَّهُ أَكْبَرُ",
          "count": 34,
          "ref": "البخاري ومسلم",
          "hint": "خيراً له من خادم",
        },
      ],
    },
  ];

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FA),
      appBar: AppBar(
        title: const Text("الأذكار"),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 4,
      ),
      bottomNavigationBar: const Rashad(currentIndex: 3),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          // Intro card — modern gradient + soft shadow
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.white,
                  const Color(0xFF2196F3).withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2196F3).withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF1565C0),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    introText,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.7,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Sections
          ...sections.map((section) => _SectionCard(
                title: section["title"],
                items: List<Map<String, dynamic>>.from(section["items"]),
              )),
        ],
      ),
    );
  }
}

// ---------------- Section Card ----------------

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;

  const _SectionCard({
    required this.title,
    required this.items,
  });

  IconData _iconForTitle(String title) {
    if (title.contains("الصباح")) return Icons.wb_sunny_rounded;
    if (title.contains("المساء")) return Icons.nightlight_round;
    if (title.contains("النوم")) return Icons.bed_rounded;
    return Icons.auto_awesome_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _iconForTitle(title),
            color: const Color(0xFF1565C0),
            size: 22,
          ),
        ),
        title: Text(
          title,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
            letterSpacing: 0.2,
          ),
        ),
        children: [
          for (final z in items)
            _ZekrCard(
              text: (z["text"] ?? "").toString(),
              count: (z["count"] ?? 1) as int,
              ref: (z["ref"] ?? "").toString(),
              hint: z["hint"]?.toString(),
            ),
        ],
      ),
    );
  }
}

// ---------------- Zekr Card ----------------

class _ZekrCard extends StatelessWidget {
  final String text;
  final int count;
  final String ref;
  final String? hint;

  const _ZekrCard({
    required this.text,
    required this.count,
    required this.ref,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          right: BorderSide(
            color: const Color(0xFF2196F3).withOpacity(0.35),
            width: 3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              text,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 15,
                height: 1.7,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A237E),
              ),
            ),
            if (hint != null && hint!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        size: 16, color: Colors.blueGrey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hint!,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$count مرة",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ref,
                    textAlign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
