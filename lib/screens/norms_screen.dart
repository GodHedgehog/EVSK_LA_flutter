import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/discipline_data.dart';
import '../models/medal_item.dart';
import '../services/data_loader.dart';
import '../utils/time_formatter.dart';
import '../widgets/medal_card.dart';
import '../widgets/selector_row.dart';
import 'about_screen.dart';

class NormsScreen extends StatefulWidget {
  const NormsScreen({super.key});

  @override
  State<NormsScreen> createState() => _NormsScreenState();
}

class _NormsScreenState extends State<NormsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final List<String> genders = ["мужчины", "женщины"];
  int genderIndex = 0;
  
  List<String> categories = [];
  int categoryIndex = 0;
  
  List<String> disciplines = [];
  int disciplineIndex = 0;
  
  List<TimingOption> timingOptions = [];
  int timingIndex = 0;
  
  final Map<String, List<DisciplineData>> dataCache = {};
  List<MedalItem> medalItems = [];
  
  final List<String> rankOrder = [
    "мастер спорта международного класса",
    "мсмк",
    "мастер спорта",
    "мс",
    "кандидат мастера спорта",
    "кандидат в мастера спорта",
    "кмс",
    "1 взрослый",
    "2 взрослый",
    "3 взрослый",
    "1 юношеский",
    "2 юношеский",
    "3 юношеский"
  ].map((e) => e.toLowerCase()).toList();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _updateGender();
  }

  Future<void> _updateGender() async {
    final genderKey = genders[genderIndex];
    if (!dataCache.containsKey(genderKey)) {
      final data = await DataLoader.loadAllDataFromAssets(genderKey);
      dataCache[genderKey] = data;
    }
    setState(() {
      categories = _computeCategories();
      categoryIndex = 0;
      _updateCategory();
    });
  }

  void _updateCategory() {
    if (categories.isEmpty) {
      setState(() {
        disciplines = [];
        medalItems = [];
      });
      return;
    }
    setState(() {
      disciplines = _computeDisciplines();
      disciplineIndex = 0;
      _updateDiscipline();
    });
  }

  void _updateDiscipline() {
    if (disciplines.isEmpty) {
      setState(() {
        medalItems = [];
        timingOptions = [];
      });
      return;
    }
    setState(() {
      timingOptions = _computeTimingOptions();
      timingIndex = 0;
      _updateTiming();
    });
  }

  void _updateTiming() {
    if (timingOptions.isEmpty) {
      setState(() {
        medalItems = [];
      });
      return;
    }
    final option = timingOptions[timingIndex];
    setState(() {
      _updateMedalGrid(option);
    });
  }

  void _updateMedalGrid(TimingOption? option) {
    final discipline = disciplines.isNotEmpty ? disciplines[disciplineIndex] : null;
    final category = categories.isNotEmpty ? categories[categoryIndex] : null;
    
    if (discipline == null || category == null) {
      medalItems = [];
      return;
    }

    final data = _getCurrentData()
        .where((item) => _determineCategory(item.name) == category)
        .where((item) => item.name == discipline)
        .where((item) {
          if (option == null) return true;
          final trackMatches = (option.trackType == null && (item.trackType == null || item.trackType!.isEmpty)) ||
              (option.trackType?.toLowerCase() == item.trackType?.toLowerCase());
          final timingMatches = (option.timingType == null && (item.timingType == null || item.timingType!.isEmpty)) ||
              (option.timingType?.toLowerCase() == item.timingType?.toLowerCase());
          return trackMatches && timingMatches;
        })
        .toList();

    final sorted = data..sort((a, b) {
      final idxA = rankOrder.indexOf(a.rank.toLowerCase());
      final idxB = rankOrder.indexOf(b.rank.toLowerCase());
      final valA = idxA == -1 ? rankOrder.length : idxA;
      final valB = idxB == -1 ? rankOrder.length : idxB;
      return valA.compareTo(valB);
    });

    medalItems = sorted.map((item) {
      return MedalItem(
        rank: item.rank,
        timeText: TimeFormatter.format(item.time),
      );
    }).toList();
  }

  List<String> _computeCategories() {
    return _getCurrentData()
        .map((item) => _determineCategory(item.name))
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _computeDisciplines() {
    final category = categories.isNotEmpty ? categories[categoryIndex] : null;
    if (category == null) return [];
    
    final data = _getCurrentData();
    final disciplineSet = data
        .where((item) => _determineCategory(item.name) == category)
        .map((item) => item.name)
        .toSet();
    
    final order = <String>[];
    for (final item in data) {
      if (disciplineSet.contains(item.name) && !order.contains(item.name)) {
        order.add(item.name);
      }
    }
    return order;
  }

  List<TimingOption> _computeTimingOptions() {
    final discipline = disciplines.isNotEmpty ? disciplines[disciplineIndex] : null;
    if (discipline == null) return [];
    
    final seen = <String>{};
    final options = <TimingOption>[];
    
    for (final item in _getCurrentData().where((item) => item.name == discipline)) {
      final key = "${item.trackType}|${item.timingType}";
      if (!seen.contains(key)) {
        seen.add(key);
        options.add(TimingOption(
          label: _buildTimingLabel(item.trackType, item.timingType),
          trackType: item.trackType,
          timingType: item.timingType,
        ));
      }
    }
    
    return options.isEmpty
        ? [TimingOption(label: "Общий", trackType: null, timingType: null)]
        : options;
  }

  List<DisciplineData> _getCurrentData() {
    final genderKey = genders[genderIndex];
    return dataCache[genderKey] ?? [];
  }

  String _determineCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains("эстаф")) return "Эстафета";
    if (lower.contains("барьер")) return "Бег с барьерами";
    if (lower.contains("препят") || lower.contains("ям")) return "Бег с препятствиями";
    if (lower.contains("ходьб")) return "Ходьба";
    if (lower.contains("кросс")) return "Кросс";
    if (lower.contains("шосс")) return "Бег по шоссе";
    return "Бег";
  }

  String _buildTimingLabel(String? track, String? timing) {
    final parts = <String>[];
    if (track != null && track.isNotEmpty) {
      parts.add(track);
    }
    if (timing != null && timing.isNotEmpty) {
      parts.add(
        timing.toLowerCase().startsWith("авто")
            ? "Автохронометраж"
            : "Ручной хронометраж"
      );
    }
    return parts.isEmpty ? "Общий" : parts.join(" ");
  }

  void _changeGender(int step) {
    setState(() {
      genderIndex = (genderIndex + step + genders.length) % genders.length;
    });
    _updateGender();
  }

  void _changeCategory(int step) {
    if (categories.isEmpty) return;
    setState(() {
      categoryIndex = (categoryIndex + step + categories.length) % categories.length;
    });
    _updateCategory();
  }

  void _changeDiscipline(int step) {
    if (disciplines.isEmpty) return;
    setState(() {
      disciplineIndex = (disciplineIndex + step + disciplines.length) % disciplines.length;
    });
    _updateDiscipline();
  }

  void _changeTiming(int step) {
    if (timingOptions.isEmpty) return;
    setState(() {
      timingIndex = (timingIndex + step + timingOptions.length) % timingOptions.length;
    });
    _updateTiming();
  }

  void _checkForUpdates() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Проверить обновление"),
        content: const Padding(
          padding: EdgeInsets.fromLTRB(50, 40, 50, 40),
          child: Text(
            "Проверить обновление можно в Telegram-канале разработчика",
            style: TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ЗАКРЫТЬ"),
          ),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse("https://t.me/evskla");
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                // Ignore errors
              }
              Navigator.pop(context);
            },
            child: const Text("ОТКРЫТЬ КАНАЛ"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genderText = genders[genderIndex];
    final genderLabel = genderText.isEmpty 
        ? genderText 
        : genderText[0].toUpperCase() + genderText.substring(1);
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: 280,
        child: Column(
          children: [
            Container(
              height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFFBBBBBB),
                image: DecorationImage(
                  image: AssetImage('assets/images/rs_flag.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Stack(
                children: [
                  Positioned(
                    bottom: 38,
                    left: 0,
                    right: 0,
                    child: Text(
                      'Нормативы',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.only(right: 20),
                      child: Text(
                        'Лёгкой атлетики',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.info, color: Color(0xFF424242), size: 24),
                      title: const Text(
                        'О программе',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF424242),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AboutScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.update, color: Color(0xFF424242), size: 24),
                      title: const Text(
                        'Проверить обновление',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF424242),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      onTap: () {
                        Navigator.pop(context);
                        _checkForUpdates();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_track_placeholder.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Лёгкая Атлетика',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Нормативы',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 18,
                    ),
                    itemCount: medalItems.length,
                    itemBuilder: (context, index) {
                      return MedalCard(item: medalItems[index]);
                    },
                  ),
                ),
                const SizedBox(height: 5),
                SelectorRow(
                  value: genderLabel,
                  onPrev: () => _changeGender(-1),
                  onNext: () => _changeGender(1),
                ),
                const SizedBox(height: 5),
                SelectorRow(
                  value: categories.isEmpty ? "Нет данных" : categories[categoryIndex],
                  onPrev: categories.isEmpty ? null : () => _changeCategory(-1),
                  onNext: categories.isEmpty ? null : () => _changeCategory(1),
                ),
                const SizedBox(height: 5),
                SelectorRow(
                  value: disciplines.isEmpty ? "—" : disciplines[disciplineIndex],
                  onPrev: disciplines.isEmpty ? null : () => _changeDiscipline(-1),
                  onNext: disciplines.isEmpty ? null : () => _changeDiscipline(1),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SelectorRow(
                    value: timingOptions.isEmpty
                        ? "Общий"
                        : timingOptions[timingIndex].label,
                    onPrev: timingOptions.isEmpty ? null : () => _changeTiming(-1),
                    onNext: timingOptions.isEmpty ? null : () => _changeTiming(1),
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

class TimingOption {
  final String label;
  final String? trackType;
  final String? timingType;

  TimingOption({
    required this.label,
    this.trackType,
    this.timingType,
  });
}

