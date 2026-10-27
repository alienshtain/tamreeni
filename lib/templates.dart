// مكتبة التمارين الجاهزة وقوالب الخطط.
import 'catalog.dart';
import 'models.dart';

Exercise _e(String id, String name, String emoji, String cat, String type,
        String equip,
        [String notes = '']) =>
    Exercise(
        id: id,
        name: name,
        emoji: emoji,
        category: cat,
        type: type,
        equipment: equip,
        notes: notes);

/// المكتبة الأساسية: من الكتالوج إن كان محمّلاً، وإلا القائمة المضمّنة أدناه.
List<Exercise> defaultExercises() {
  final base = legacyDefaults();
  if (!catalog.loaded) return base;
  return base.map((e) => catalog.byId(e.id) ?? e).toList();
}

/// القائمة القديمة (تُستعمل كاحتياط ولمعرفة هل عدّل المستخدم التمرين).
List<Exercise> legacyDefaults() => [
      // صدر
      _e('pushup', 'ضغط', '💪', 'صدر', 'reps', 'bodyweight'),
      _e('incline_pushup', 'ضغط مائل (يدان مرتفعتان)', '📐', 'صدر', 'reps', 'bodyweight'),
      _e('decline_pushup', 'ضغط بقدمين مرتفعتين', '⛰️', 'صدر', 'reps', 'calisthenics'),
      _e('diamond_pushup', 'ضغط الماس', '💎', 'صدر', 'reps', 'calisthenics'),
      _e('db_bench', 'ضغط صدر بالدمبل', '🏋️', 'صدر', 'reps', 'weights'),
      _e('db_incline', 'ضغط صدر علوي بالدمبل', '🏋️', 'صدر', 'reps', 'weights'),
      _e('db_fly', 'فتح صدر بالدمبل', '🦅', 'صدر', 'reps', 'weights'),
      _e('dips', 'متوازي (Dips)', '🔻', 'صدر', 'reps', 'calisthenics'),
      // ظهر
      _e('pullup', 'عقلة', '🧗', 'ظهر', 'reps', 'calisthenics'),
      _e('chinup', 'عقلة بقبضة عكسية', '🧗', 'ظهر', 'reps', 'calisthenics'),
      _e('db_row', 'تجديف بالدمبل', '🚣', 'ظهر', 'reps', 'weights'),
      _e('inv_row', 'تجديف مقلوب (تحت طاولة)', '🚣', 'ظهر', 'reps', 'bodyweight'),
      _e('reverse_fly', 'فتح خلفي بالدمبل', '🦋', 'ظهر', 'reps', 'weights'),
      _e('db_pullover', 'بولوفر بالدمبل', '🌀', 'ظهر', 'reps', 'weights'),
      _e('superman', 'سوبرمان', '🦸', 'ظهر', 'time', 'bodyweight'),
      // أكتاف
      _e('db_press', 'ضغط أكتاف بالدمبل', '🏋️', 'أكتاف', 'reps', 'weights'),
      _e('lateral_raise', 'رفرفة جانبية', '🕊️', 'أكتاف', 'reps', 'weights'),
      _e('front_raise', 'رفع أمامي', '⬆️', 'أكتاف', 'reps', 'weights'),
      _e('shrug', 'شرقات (Shrugs)', '🤷', 'أكتاف', 'reps', 'weights'),
      _e('pike_pushup', 'ضغط بايك', '🔺', 'أكتاف', 'reps', 'calisthenics'),
      // ذراعين
      _e('db_curl', 'بايسبس بالدمبل', '💪', 'ذراعين', 'reps', 'weights'),
      _e('hammer_curl', 'هامر كيرل', '🔨', 'ذراعين', 'reps', 'weights'),
      _e('tri_ext', 'ترايسبس خلف الرأس', '🏋️', 'ذراعين', 'reps', 'weights'),
      _e('kickback', 'ترايسبس كيك باك', '🦵', 'ذراعين', 'reps', 'weights'),
      _e('chair_dips', 'ترايسبس على كرسي', '🪑', 'ذراعين', 'reps', 'bodyweight'),
      // أرجل
      _e('squat', 'سكوات', '🦵', 'أرجل', 'reps', 'bodyweight'),
      _e('goblet', 'سكوات جوبلت', '🏆', 'أرجل', 'reps', 'weights'),
      _e('lunge', 'اندفاع (Lunges)', '🚶', 'أرجل', 'reps', 'bodyweight'),
      _e('db_lunge', 'اندفاع بالدمبل', '🚶', 'أرجل', 'reps', 'weights'),
      _e('bulgarian', 'سكوات بلغاري', '🇧🇬', 'أرجل', 'reps', 'calisthenics'),
      _e('rdl', 'رفعة رومانية بالدمبل', '🏋️', 'أرجل', 'reps', 'weights'),
      _e('glute_bridge', 'جسر الأرداف', '🌉', 'أرجل', 'reps', 'bodyweight'),
      _e('calf_raise', 'رفع السمانة', '🦶', 'أرجل', 'reps', 'bodyweight'),
      _e('step_up', 'صعود الكرسي', '🪜', 'أرجل', 'reps', 'bodyweight'),
      _e('jump_squat', 'سكوات قفز', '🦘', 'أرجل', 'reps', 'calisthenics'),
      _e('wall_sit', 'جلوس على الحائط', '🧱', 'أرجل', 'time', 'bodyweight'),
      // بطن
      _e('plank', 'بلانك', '🧘', 'بطن', 'time', 'bodyweight'),
      _e('side_plank', 'بلانك جانبي', '↔️', 'بطن', 'time', 'bodyweight'),
      _e('crunch', 'كرنش', '🔥', 'بطن', 'reps', 'bodyweight'),
      _e('leg_raise', 'رفع الأرجل', '🦵', 'بطن', 'reps', 'calisthenics'),
      _e('russian', 'التفاف روسي', '🌪️', 'بطن', 'reps', 'bodyweight'),
      _e('mountain', 'متسلق الجبال', '⛰️', 'بطن', 'time', 'bodyweight'),
      _e('hollow', 'هولو هولد', '🌙', 'بطن', 'time', 'calisthenics'),
      // كارديو
      _e('jumping_jacks', 'قفز النجمة', '⭐', 'كارديو', 'time', 'bodyweight'),
      _e('jump_rope', 'نط الحبل', '➰', 'كارديو', 'time', 'bodyweight'),
      _e('high_knees', 'ركض برفع الركبة', '🏃', 'كارديو', 'time', 'bodyweight'),
      _e('burpee', 'بيربي', '💥', 'كارديو', 'reps', 'bodyweight'),
      // إحماء
      _e('wu_jog', 'ركض في المكان', '🏃', 'إحماء', 'time', 'bodyweight'),
      _e('wu_arm', 'دوران الذراعين', '🔄', 'إحماء', 'time', 'bodyweight'),
      _e('wu_hip', 'دوران الحوض', '🌀', 'إحماء', 'time', 'bodyweight'),
      // تمدد
      _e('st_chest', 'تمدد الصدر', '🧎', 'تمدد', 'time', 'bodyweight'),
      _e('st_shoulder', 'تمدد الكتف', '🙆', 'تمدد', 'time', 'bodyweight'),
      _e('st_quad', 'تمدد الفخذ الأمامي', '🦵', 'تمدد', 'time', 'bodyweight'),
      _e('st_hamstring', 'تمدد الفخذ الخلفي', '🙇', 'تمدد', 'time', 'bodyweight'),
      _e('st_child', 'وضعية الطفل', '🧒', 'تمدد', 'time', 'bodyweight'),
    ];

// ---------- مواصفات العناصر ----------
class ItemSpec {
  final String id;
  final int sets;
  final int reps;
  final int seconds;
  final double weight;
  final double inc;
  final int rest;
  const ItemSpec(this.id, this.sets,
      {this.reps = 0,
      this.seconds = 0,
      this.weight = 0,
      this.inc = 0,
      this.rest = 90});
}

ItemSpec _r(String id, int sets, int reps,
        {double w = 0, double inc = 0, int rest = 90}) =>
    ItemSpec(id, sets, reps: reps, weight: w, inc: inc, rest: rest);
ItemSpec _t(String id, int sets, int sec, {int rest = 45}) =>
    ItemSpec(id, sets, seconds: sec, rest: rest);

final Map<String, Map<String, List<ItemSpec>>> kDayContent = {
  'upper': {
    'weights': [
      _r('db_bench', 4, 10, w: 14, inc: 2),
      _r('db_row', 4, 10, w: 14, inc: 2),
      _r('db_press', 3, 10, w: 10, inc: 1, rest: 75),
      _r('lateral_raise', 3, 12, w: 4, inc: 1, rest: 60),
      _r('db_curl', 3, 12, w: 8, inc: 1, rest: 60),
      _r('tri_ext', 3, 12, w: 8, inc: 1, rest: 60),
    ],
    'bodyweight': [
      _r('pushup', 4, 15),
      _r('chair_dips', 3, 12, rest: 75),
      _r('inv_row', 3, 10),
      _t('superman', 3, 30),
      _t('plank', 3, 45),
    ],
    'calisthenics': [
      _r('pullup', 4, 6),
      _r('dips', 3, 8),
      _r('pike_pushup', 3, 8),
      _r('inv_row', 3, 10),
      _r('diamond_pushup', 3, 10, rest: 75),
    ],
  },
  'lower': {
    'weights': [
      _r('goblet', 4, 12, w: 16, inc: 2),
      _r('rdl', 4, 10, w: 16, inc: 2),
      _r('db_lunge', 3, 10, w: 10, inc: 2, rest: 75),
      _r('glute_bridge', 3, 15, rest: 60),
      _r('calf_raise', 4, 15, rest: 45),
      _t('plank', 3, 45),
    ],
    'bodyweight': [
      _r('squat', 4, 20),
      _r('lunge', 3, 12),
      _r('glute_bridge', 3, 20, rest: 60),
      _r('calf_raise', 4, 20, rest: 45),
      _t('wall_sit', 3, 40),
      _t('plank', 3, 45),
    ],
    'calisthenics': [
      _r('bulgarian', 3, 10),
      _r('jump_squat', 3, 12),
      _r('step_up', 3, 12, rest: 75),
      _r('glute_bridge', 3, 20, rest: 60),
      _r('calf_raise', 4, 20, rest: 45),
      _r('leg_raise', 3, 12, rest: 60),
    ],
  },
  'push': {
    'weights': [
      _r('db_bench', 4, 10, w: 14, inc: 2),
      _r('db_incline', 3, 10, w: 12, inc: 2),
      _r('db_press', 3, 10, w: 10, inc: 1, rest: 75),
      _r('lateral_raise', 3, 12, w: 4, inc: 1, rest: 60),
      _r('tri_ext', 3, 12, w: 8, inc: 1, rest: 60),
    ],
    'bodyweight': [
      _r('pushup', 4, 15),
      _r('incline_pushup', 3, 15),
      _r('chair_dips', 3, 12, rest: 75),
      _r('crunch', 3, 20, rest: 45),
    ],
    'calisthenics': [
      _r('dips', 4, 8),
      _r('decline_pushup', 3, 12),
      _r('pike_pushup', 3, 8),
      _r('diamond_pushup', 3, 10, rest: 75),
    ],
  },
  'pull': {
    'weights': [
      _r('db_row', 4, 10, w: 14, inc: 2),
      _r('reverse_fly', 3, 12, w: 5, inc: 1, rest: 60),
      _r('db_pullover', 3, 12, w: 12, inc: 2, rest: 75),
      _r('db_curl', 3, 12, w: 8, inc: 1, rest: 60),
      _r('hammer_curl', 3, 12, w: 8, inc: 1, rest: 60),
      _r('shrug', 3, 15, w: 14, inc: 2, rest: 60),
    ],
    'bodyweight': [
      _r('inv_row', 4, 10),
      _t('superman', 4, 30),
      _t('plank', 3, 45),
    ],
    'calisthenics': [
      _r('pullup', 4, 6),
      _r('chinup', 3, 6),
      _r('inv_row', 3, 10),
      _t('hollow', 3, 25),
    ],
  },
  'legs': {
    'weights': [
      _r('goblet', 4, 12, w: 16, inc: 2),
      _r('rdl', 4, 10, w: 16, inc: 2),
      _r('db_lunge', 3, 10, w: 10, inc: 2, rest: 75),
      _r('glute_bridge', 3, 15, rest: 60),
      _r('calf_raise', 4, 15, rest: 45),
    ],
    'bodyweight': [
      _r('squat', 4, 20),
      _r('lunge', 3, 12),
      _r('glute_bridge', 3, 20, rest: 60),
      _r('calf_raise', 4, 20, rest: 45),
      _t('wall_sit', 3, 40),
    ],
    'calisthenics': [
      _r('bulgarian', 3, 10),
      _r('jump_squat', 3, 12),
      _r('step_up', 3, 12, rest: 75),
      _r('calf_raise', 4, 20, rest: 45),
      _r('leg_raise', 3, 12, rest: 60),
    ],
  },
  'full': {
    'weights': [
      _r('goblet', 3, 12, w: 16, inc: 2),
      _r('db_bench', 3, 10, w: 14, inc: 2),
      _r('db_row', 3, 10, w: 14, inc: 2),
      _r('db_press', 3, 10, w: 10, inc: 1, rest: 75),
      _r('rdl', 3, 10, w: 16, inc: 2),
      _t('plank', 3, 45),
    ],
    'bodyweight': [
      _r('squat', 3, 20),
      _r('pushup', 3, 15),
      _r('inv_row', 3, 10),
      _r('lunge', 3, 12),
      _t('plank', 3, 45),
    ],
    'calisthenics': [
      _r('pullup', 3, 6),
      _r('dips', 3, 8),
      _r('bulgarian', 3, 10),
      _r('pike_pushup', 3, 8),
      _r('leg_raise', 3, 12, rest: 60),
    ],
  },
};

final Map<String, List<String>> kStretchFor = {
  'upper': ['st_chest', 'st_shoulder'],
  'push': ['st_chest', 'st_shoulder'],
  'pull': ['st_shoulder', 'st_child'],
  'lower': ['st_quad', 'st_hamstring'],
  'legs': ['st_quad', 'st_hamstring'],
  'full': ['st_chest', 'st_quad', 'st_hamstring'],
};

const kDayMeta = {
  'upper': ['علوي', '💪'],
  'lower': ['سفلي', '🦵'],
  'push': ['دفع', '🏋️'],
  'pull': ['سحب', '🧗'],
  'legs': ['أرجل', '🦵'],
  'full': ['جسم كامل', '🔥'],
};

class PlanTemplate {
  final String id;
  final String name;
  final String desc;
  final List<String> pattern; // مفاتيح الأيام + rest
  const PlanTemplate(this.id, this.name, this.desc, this.pattern);
}

const kTemplates = [
  PlanTemplate('ul_rest', 'علوي / راحة / سفلي / راحة',
      'يوم علوي ثم راحة ثم سفلي ثم راحة، مناسب للمبتدئ', [
    'upper',
    'rest',
    'lower',
    'rest'
  ]),
  PlanTemplate('ul3', 'علوي / سفلي / راحة',
      'يومان تمرين ثم راحة، تكرار أكثر لكل عضلة', ['upper', 'lower', 'rest']),
  PlanTemplate('ppl', 'دفع / سحب / أرجل / راحة',
      'تقسيم كلاسيكي PPL لعضلات أكثر تفصيلاً', [
    'push',
    'pull',
    'legs',
    'rest'
  ]),
  PlanTemplate('full', 'جسم كامل يوم بعد يوم',
      'تمرين كامل الجسم ثم راحة، مناسب للبداية', ['full', 'rest']),
  PlanTemplate('blank', 'خطة فارغة (أبنيها بنفسي)',
      'يوم تمرين ويوم راحة، وتضيف التمارين بنفسك', ['custom', 'rest']),
];

/// يبني خطة من قالب. يضيف للمكتبة أي تمرين ناقص من التمارين الجاهزة.
Plan buildPlanFromTemplate(
  PlanTemplate t, {
  required String equipment,
  required int totalDays,
  required DateTime startDate,
  required bool warmup,
  required bool stretch,
  required bool shiftOnMiss,
  required List<Exercise> library,
}) {
  final defaults = {for (final e in defaultExercises()) e.id: e};
  void ensure(String id) {
    if (!library.any((e) => e.id == id) && defaults.containsKey(id)) {
      library.add(defaults[id]!);
    }
  }

  final types = <DayType>[];
  final used = <String>[];
  for (final key in t.pattern) {
    if (!used.contains(key)) used.add(key);
  }
  for (final key in used) {
    if (key == 'rest') {
      types.add(DayType(id: 'rest', name: 'راحة', kind: 'rest', emoji: '😴'));
      continue;
    }
    if (key == 'custom') {
      types.add(DayType(id: 'custom', name: 'يوم تمرين', emoji: '💪'));
      continue;
    }
    final meta = kDayMeta[key] ?? [key, '💪'];
    final dt = DayType(id: key, name: meta[0], emoji: meta[1]);
    if (warmup) {
      for (final id in ['wu_jog', 'wu_arm', 'wu_hip']) {
        ensure(id);
        dt.items.add(PlanItem(
            exerciseId: id,
            role: 'warmup',
            sets: 1,
            seconds: 30,
            reps: 0,
            restSeconds: 10));
      }
    }
    final specs = kDayContent[key]?[equipment] ?? kDayContent[key]?['bodyweight'] ?? [];
    for (final s in specs) {
      ensure(s.id);
      dt.items.add(PlanItem(
        exerciseId: s.id,
        role: 'main',
        sets: s.sets,
        reps: s.reps,
        seconds: s.seconds,
        restSeconds: s.rest,
        weight: s.weight,
        increment: s.inc,
      ));
    }
    if (stretch) {
      for (final id in (kStretchFor[key] ?? <String>[])) {
        ensure(id);
        dt.items.add(PlanItem(
            exerciseId: id,
            role: 'cooldown',
            sets: 1,
            seconds: 30,
            reps: 0,
            restSeconds: 10));
      }
    }
    types.add(dt);
  }
  return Plan(
    id: newId(),
    name: t.id == 'blank' ? 'خطتي' : t.name,
    totalDays: totalDays,
    startDate: dateOnly(startDate),
    pattern: List<String>.from(t.pattern),
    dayTypes: types,
    equipment: equipment,
    shiftOnMiss: shiftOnMiss,
  );
}
