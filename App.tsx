import React, { useState } from 'react';
import {
  ActivityIndicator,
  Modal,
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import * as SecureStore from 'expo-secure-store';

type Language = 'de' | 'sq';
type Tab = 'translate' | 'practice' | 'progress';

type Exercise = {
  id: number;
  prompt: string;
  answer: string;
  options: string[];
  direction: string;
};

const COLORS = {
  bg: '#0B0B0D',
  card: '#151518',
  card2: '#1D1D21',
  text: '#F7F7F8',
  muted: '#9A9AA2',
  red: '#E5243F',
  redDark: '#A9132A',
  green: '#40C986',
  border: '#2B2B31',
  white: '#FFFFFF',
};

const PHRASES: Record<string, string> = {
  'hallo': 'përshëndetje',
  'guten morgen': 'mirëmëngjes',
  'guten abend': 'mirëmbrëma',
  'wie geht es dir': 'si je',
  'wie geht es dir?': 'si je?',
  'mir geht es gut': 'jam mirë',
  'danke': 'faleminderit',
  'bitte': 'të lutem',
  'ich liebe dich': 'të dua',
  'ich vermisse dich': 'më mungon',
  'wo bist du': 'ku je',
  'wo bist du?': 'ku je?',
  'was machst du': 'çka po bën',
  'was machst du?': 'çka po bën?',
  'ich bin zuhause': 'jam në shtëpi',
  'ich bin zu hause': 'jam në shtëpi',
  'ich gehe arbeiten': 'po shkoj në punë',
  'ich gehe morgen arbeiten': 'nesër po shkoj në punë',
  'ich habe hunger': 'jam i uritur',
  'ich habe durst': 'kam etje',
  'gute nacht': 'natën e mirë',
  'bis morgen': 'shihemi nesër',
  'bis später': 'shihemi më vonë',
  'kein problem': 's’ka problem',
  'ja': 'po',
  'nein': 'jo',
  'komm': 'eja',
  'warte': 'prit',
  'warte auf mich': 'më prit',
  'ich warte auf dich': 'po të pres',
  'ich bin immer noch am warten': 'hala jam tu prit',
  'ich verstehe nicht': 'nuk kuptoj',
  'sprich langsam': 'fol ngadalë',
  'wie heißt du': 'si quhesh',
  'wie heißt du?': 'si quhesh?',
  'ich heiße': 'quhem',
  'woher kommst du': 'prej nga je',
  'woher kommst du?': 'prej nga je?',
  'ich komme aus deutschland': 'jam nga gjermania',
  'ich komme aus kosovo': 'jam nga kosova',
  'ich kann albanisch': 'di shqip',
  'ich lerne albanisch': 'po mësoj shqip',
};

const WORDS: Record<string, string> = {
  ich: 'unë',
  du: 'ti',
  er: 'ai',
  sie: 'ajo',
  wir: 'ne',
  ihr: 'ju',
  heute: 'sot',
  morgen: 'nesër',
  gestern: 'dje',
  gut: 'mirë',
  schlecht: 'keq',
  schön: 'bukur',
  haus: 'shtëpi',
  arbeit: 'punë',
  auto: 'veturë',
  familie: 'familje',
  freund: 'shok',
  freundin: 'shoqe',
  mutter: 'nënë',
  vater: 'babë',
  bruder: 'vëlla',
  schwester: 'motër',
  essen: 'ushqim',
  wasser: 'ujë',
  kaffee: 'kafe',
  liebe: 'dashuri',
  sprechen: 'fol',
  lernen: 'mëso',
  danke: 'faleminderit',
  hallo: 'përshëndetje',
};

const REVERSE_PHRASES: Record<string, string> = Object.fromEntries(
  Object.entries(PHRASES).map(([de, sq]) => [sq.toLowerCase(), de])
);
const REVERSE_WORDS: Record<string, string> = Object.fromEntries(
  Object.entries(WORDS).map(([de, sq]) => [sq.toLowerCase(), de])
);

const EXERCISES: Exercise[] = [
  { id: 1, prompt: 'Hallo', answer: 'Përshëndetje', options: ['Përshëndetje', 'Faleminderit', 'Natën e mirë', 'Mirë'], direction: 'Deutsch → Albanisch' },
  { id: 2, prompt: 'Danke', answer: 'Faleminderit', options: ['Të dua', 'Faleminderit', 'Prit', 'Sot'], direction: 'Deutsch → Albanisch' },
  { id: 3, prompt: 'Ich liebe dich', answer: 'Të dua', options: ['Të dua', 'Ku je?', 'Si je?', 'Po të pres'], direction: 'Deutsch → Albanisch' },
  { id: 4, prompt: 'Ku je?', answer: 'Wo bist du?', options: ['Was machst du?', 'Wie geht es dir?', 'Wo bist du?', 'Woher kommst du?'], direction: 'Albanisch → Deutsch' },
  { id: 5, prompt: 'Nesër', answer: 'Morgen', options: ['Heute', 'Gestern', 'Morgen', 'Später'], direction: 'Albanisch → Deutsch' },
  { id: 6, prompt: 'Was machst du?', answer: 'Çka po bën?', options: ['Si je?', 'Çka po bën?', 'Ku je?', 'Prej nga je?'], direction: 'Deutsch → Kosovo-Albanisch' },
  { id: 7, prompt: 'Po të pres', answer: 'Ich warte auf dich', options: ['Ich rufe dich an', 'Ich warte auf dich', 'Ich komme gleich', 'Ich verstehe dich'], direction: 'Albanisch → Deutsch' },
  { id: 8, prompt: 'Gute Nacht', answer: 'Natën e mirë', options: ['Mirëmëngjes', 'Mirëmbrëma', 'Natën e mirë', 'Shihem nesër'], direction: 'Deutsch → Albanisch' },
  { id: 9, prompt: 'S’ka problem', answer: 'Kein Problem', options: ['Kein Problem', 'Keine Zeit', 'Keine Ahnung', 'Kein Geld'], direction: 'Albanisch → Deutsch' },
  { id: 10, prompt: 'Ich lerne Albanisch', answer: 'Po mësoj shqip', options: ['Di shqip', 'Po mësoj shqip', 'Fol shqip', 'Nuk kuptoj'], direction: 'Deutsch → Albanisch' },
];

function normalize(text: string) {
  return text.trim().toLowerCase().replace(/\s+/g, ' ');
}

function preserveSentenceCase(source: string, result: string) {
  if (!source || !result) return result;
  return source[0] === source[0].toUpperCase()
    ? result.charAt(0).toUpperCase() + result.slice(1)
    : result;
}

function offlineTranslate(text: string, from: Language, to: Language) {
  if (!text.trim()) return '';
  if (from === to) return text;

  const key = normalize(text);
  const phraseMap = from === 'de' ? PHRASES : REVERSE_PHRASES;
  const wordMap = from === 'de' ? WORDS : REVERSE_WORDS;

  if (phraseMap[key]) return preserveSentenceCase(text, phraseMap[key]);

  const punctuation = text.match(/[.!?]+$/)?.[0] ?? '';
  const clean = key.replace(/[.!?]+$/, '');
  const translated = clean
    .split(' ')
    .map((word) => wordMap[word] ?? word)
    .join(' ');

  const knownCount = clean
    .split(' ')
    .filter((word) => Boolean(wordMap[word])).length;

  if (knownCount === 0) {
    return from === 'de'
      ? 'Noch nicht im Offline-Wörterbuch. Diese Beta lernt gerade neue Sätze.'
      : 'Noch nicht im Offline-Wörterbuch. Diese Beta lernt gerade neue Sätze.';
  }

  return preserveSentenceCase(text, translated + punctuation);
}

function Pill({ label, active, onPress }: { label: string; active?: boolean; onPress?: () => void }) {
  return (
    <TouchableOpacity onPress={onPress} activeOpacity={0.8} style={[styles.pill, active && styles.pillActive]}>
      <Text style={[styles.pillText, active && styles.pillTextActive]}>{label}</Text>
    </TouchableOpacity>
  );
}

function AppHeader() {
  return (
    <View style={styles.header}>
      <View style={styles.logoBox}><Text style={styles.logoLetter}>F</Text></View>
      <View>
        <Text style={styles.logo}>FOL</Text>
        <Text style={styles.tagline}>Übersetzen. Lernen. Sprechen.</Text>
      </View>
    </View>
  );
}

function TranslateScreen() {
  const [from, setFrom] = useState<Language>('de');
  const [to, setTo] = useState<Language>('sq');
  const [input, setInput] = useState('');
  const [result, setResult] = useState('');
  const [apiKey, setApiKey] = useState('');
  const [apiKeyDraft, setApiKeyDraft] = useState('');
  const [showKeySetup, setShowKeySetup] = useState(false);
  const [isTranslating, setIsTranslating] = useState(false);
  const [error, setError] = useState('');

  React.useEffect(() => {
    SecureStore.getItemAsync('folGoogleTranslateApiKey')
      .then((savedKey) => setApiKey(savedKey ?? ''))
      .catch(() => setError('Der gespeicherte API-Schlüssel konnte nicht geladen werden.'));
  }, []);

  const swap = () => {
    setFrom(to);
    setTo(from);
    if (result) setInput(result);
    setResult('');
    setError('');
  };

  const saveApiKey = async () => {
    const trimmedKey = apiKeyDraft.trim();
    if (!trimmedKey) {
      setError('Bitte gib zuerst deinen Google-Cloud-API-Schlüssel ein.');
      return;
    }
    try {
      await SecureStore.setItemAsync('folGoogleTranslateApiKey', trimmedKey);
      setApiKey(trimmedKey);
      setApiKeyDraft('');
      setShowKeySetup(false);
      setError('');
    } catch {
      setError('Der API-Schlüssel konnte nicht sicher auf diesem iPhone gespeichert werden.');
    }
  };

  const removeApiKey = async () => {
    await SecureStore.deleteItemAsync('folGoogleTranslateApiKey');
    setApiKey('');
    setResult('');
    setError('');
  };

  const translate = async () => {
    if (!input.trim()) {
      setError('Schreib zuerst einen Text zum Übersetzen.');
      return;
    }
    if (!apiKey) {
      setApiKeyDraft('');
      setShowKeySetup(true);
      return;
    }

    setIsTranslating(true);
    setError('');
    setResult('');
    try {
      const response = await fetch('https://translation.googleapis.com/language/translate/v2', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey,
          'X-Ios-Bundle-Identifier': 'com.betim.fol',
        },
        body: JSON.stringify({ q: input.trim(), source: from, target: to, format: 'text' }),
      });
      const payload = await response.json();
      if (!response.ok) {
        throw new Error(payload?.error?.message ?? 'Google Cloud Translation hat die Anfrage abgelehnt.');
      }
      const translated = payload?.data?.translations?.[0]?.translatedText;
      if (typeof translated !== 'string' || !translated.trim()) {
        throw new Error('Google hat keine Übersetzung zurückgegeben.');
      }
      setResult(translated
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&#39;/g, "'")
        .replace(/&quot;/g, '"'));
    } catch (translationError) {
      setError(translationError instanceof Error
        ? translationError.message
        : 'Keine Verbindung zu Google Cloud Translation. Prüfe deine Internetverbindung.');
    } finally {
      setIsTranslating(false);
    }
  };

  const examples = from === 'de'
    ? ['Wie geht es dir?', 'Was machst du?', 'Ich liebe dich', 'Bis morgen']
    : ['Ku je?', 'Si je?', 'Po të pres', 'Faleminderit'];

  return (
    <ScrollView contentContainerStyle={styles.screenContent} keyboardShouldPersistTaps="handled">
      <Text style={styles.eyebrow}>FOL TRANSLATOR</Text>
      <Text style={styles.h1}>Sag es richtig.</Text>
      <Text style={styles.subhead}>Deutsch ↔ Albanisch mit Google Cloud Translation. Bei Kosovo-Slang kann die Übersetzung abweichen.</Text>

      <View style={styles.languageRow}>
        <Pill label={from === 'de' ? '🇩🇪 Deutsch' : '🇦🇱 Albanisch'} active />
        <TouchableOpacity onPress={swap} style={styles.swapButton}><Text style={styles.swapText}>⇄</Text></TouchableOpacity>
        <Pill label={to === 'sq' ? '🇦🇱 Albanisch' : '🇩🇪 Deutsch'} active />
      </View>

      <View style={styles.apiKeyRow}>
        <View style={styles.apiKeyStatus}>
          <Text style={styles.apiKeyTitle}>Google-Übersetzung</Text>
          <Text style={styles.smallMuted}>{apiKey ? 'API-Schlüssel auf diesem iPhone gespeichert' : 'Einmalige Einrichtung erforderlich'}</Text>
        </View>
        <TouchableOpacity onPress={() => { setApiKeyDraft(''); setShowKeySetup(true); }}>
          <Text style={styles.clear}>{apiKey ? 'Ändern' : 'Einrichten'}</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardLabel}>DEIN TEXT</Text>
        <TextInput
          value={input}
          onChangeText={(text) => { setInput(text); setResult(''); setError(''); }}
          multiline
          maxLength={240}
          placeholder="Schreib etwas …"
          placeholderTextColor={COLORS.muted}
          style={styles.input}
        />
        <View style={styles.counterRow}>
          <Text style={styles.smallMuted}>{input.length}/240</Text>
          <TouchableOpacity onPress={() => setInput('')}><Text style={styles.clear}>Löschen</Text></TouchableOpacity>
        </View>
      </View>

      <TouchableOpacity onPress={translate} disabled={isTranslating} activeOpacity={0.85} style={[styles.primaryButton, isTranslating && styles.buttonDisabled]}>
        {isTranslating
          ? <ActivityIndicator color={COLORS.white} />
          : <Text style={styles.primaryButtonText}>Übersetzen</Text>}
      </TouchableOpacity>

      <View style={[styles.card, styles.resultCard]}>
        <View style={styles.resultTop}>
          <Text style={styles.cardLabel}>ÜBERSETZUNG</Text>
          <View style={styles.betaBadge}><Text style={styles.betaText}>GOOGLE CLOUD</Text></View>
        </View>
        <Text style={styles.translation}>{result || (isTranslating ? 'Übersetzung wird erstellt …' : 'Schreib einen Text und tippe auf „Übersetzen“.')}</Text>
        {!!error && <Text style={styles.translationError}>{error}</Text>}
        <Text style={styles.dialectHint}>💬 Übersetzung von Google Cloud. Umgangssprache kann anders ausfallen.</Text>
      </View>

      <Modal visible={showKeySetup} transparent animationType="fade" onRequestClose={() => setShowKeySetup(false)}>
        <View style={styles.modalBackdrop}>
          <View style={styles.modalCard}>
            <Text style={styles.infoTitle}>Google Cloud API-Schlüssel</Text>
            <Text style={styles.infoText}>Füge deinen Schlüssel hier ein. Er wird verschlüsselt auf diesem iPhone gespeichert und nicht in die IPA geschrieben. Beschränke ihn in Google Cloud auf „Cloud Translation API“ und die App-ID com.betim.fol. Teile die IPA nicht: App-Einschränkungen sind kein vollständiger Schutz vor Missbrauch.</Text>
            <TextInput
              value={apiKeyDraft}
              onChangeText={setApiKeyDraft}
              placeholder="API-Schlüssel"
              placeholderTextColor={COLORS.muted}
              secureTextEntry
              autoCapitalize="none"
              autoCorrect={false}
              style={styles.keyInput}
            />
            <TouchableOpacity onPress={saveApiKey} style={styles.primaryButton}>
              <Text style={styles.primaryButtonText}>Sicher speichern</Text>
            </TouchableOpacity>
            {apiKey ? <TouchableOpacity onPress={removeApiKey} style={styles.modalSecondaryButton}><Text style={styles.clear}>Schlüssel entfernen</Text></TouchableOpacity> : null}
            <TouchableOpacity onPress={() => { setShowKeySetup(false); setApiKeyDraft(''); }} style={styles.modalSecondaryButton}>
              <Text style={styles.smallMuted}>Abbrechen</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      <Text style={styles.sectionTitle}>Schnell ausprobieren</Text>
      <View style={styles.chipsWrap}>
        {examples.map((x) => (
          <TouchableOpacity key={x} style={styles.exampleChip} onPress={() => setInput(x)}>
            <Text style={styles.exampleText}>{x}</Text>
          </TouchableOpacity>
        ))}
      </View>

      <View style={styles.infoCard}>
        <Text style={styles.infoTitle}>Warum FOL?</Text>
        <Text style={styles.infoText}>Nicht nur übersetzen: Jeder Satz kann später automatisch zu Übungen, Vokabelkarten und Aussprache-Training werden.</Text>
      </View>
    </ScrollView>
  );
}

function PracticeScreen({ onCorrect }: { onCorrect: () => void }) {
  const [index, setIndex] = useState(0);
  const [selected, setSelected] = useState<string | null>(null);
  const [answered, setAnswered] = useState(false);
  const exercise = EXERCISES[index % EXERCISES.length];

  const choose = (option: string) => {
    if (answered) return;
    setSelected(option);
    setAnswered(true);
    if (option === exercise.answer) onCorrect();
  };

  const next = () => {
    setIndex((i) => (i + 1) % EXERCISES.length);
    setSelected(null);
    setAnswered(false);
  };

  return (
    <ScrollView contentContainerStyle={styles.screenContent}>
      <Text style={styles.eyebrow}>TÄGLICHES TRAINING</Text>
      <Text style={styles.h1}>Übung {index + 1}</Text>
      <Text style={styles.subhead}>Lerne mit kurzen Aufgaben statt stumpfem Auswendiglernen.</Text>

      <View style={styles.progressTrack}>
        <View style={[styles.progressFill, { width: `${((index % EXERCISES.length) + 1) / EXERCISES.length * 100}%` }]} />
      </View>
      <Text style={styles.progressMeta}>{exercise.direction} · {index % EXERCISES.length + 1}/{EXERCISES.length}</Text>

      <View style={[styles.card, styles.questionCard]}>
        <Text style={styles.cardLabel}>WAS BEDEUTET</Text>
        <Text style={styles.question}>“{exercise.prompt}”</Text>
      </View>

      <View style={styles.options}>
        {exercise.options.map((option, i) => {
          const isSelected = selected === option;
          const isCorrect = answered && option === exercise.answer;
          const isWrong = answered && isSelected && option !== exercise.answer;
          return (
            <TouchableOpacity
              key={option}
              onPress={() => choose(option)}
              activeOpacity={0.85}
              style={[styles.option, isCorrect && styles.optionCorrect, isWrong && styles.optionWrong]}
            >
              <Text style={styles.optionIndex}>{String.fromCharCode(65 + i)}</Text>
              <Text style={styles.optionText}>{option}</Text>
            </TouchableOpacity>
          );
        })}
      </View>

      {answered && (
        <View style={[styles.feedback, selected === exercise.answer ? styles.feedbackGood : styles.feedbackBad]}>
          <Text style={styles.feedbackTitle}>{selected === exercise.answer ? 'Richtig! 🔥' : 'Fast.'}</Text>
          <Text style={styles.feedbackText}>Richtige Antwort: {exercise.answer}</Text>
        </View>
      )}

      <TouchableOpacity onPress={next} disabled={!answered} style={[styles.primaryButton, !answered && styles.buttonDisabled]}>
        <Text style={styles.primaryButtonText}>{answered ? 'Weiter' : 'Wähle eine Antwort'}</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

function ProgressScreen({ points, correct }: { points: number; correct: number }) {
  const level = Math.floor(points / 100) + 1;
  const levelProgress = points % 100;
  return (
    <ScrollView contentContainerStyle={styles.screenContent}>
      <Text style={styles.eyebrow}>DEIN FORTSCHRITT</Text>
      <Text style={styles.h1}>Level {level}</Text>
      <Text style={styles.subhead}>Jede richtige Aufgabe bringt dich weiter.</Text>

      <View style={styles.heroStat}>
        <Text style={styles.heroStatNumber}>{points}</Text>
        <Text style={styles.heroStatLabel}>XP gesammelt</Text>
        <View style={styles.levelTrack}><View style={[styles.levelFill, { width: `${levelProgress}%` }]} /></View>
        <Text style={styles.smallMuted}>{100 - levelProgress} XP bis Level {level + 1}</Text>
      </View>

      <View style={styles.statsRow}>
        <View style={styles.statCard}><Text style={styles.statEmoji}>✅</Text><Text style={styles.statNumber}>{correct}</Text><Text style={styles.statLabel}>Richtig</Text></View>
        <View style={styles.statCard}><Text style={styles.statEmoji}>🔥</Text><Text style={styles.statNumber}>{correct > 0 ? Math.min(correct, 7) : 0}</Text><Text style={styles.statLabel}>Streak</Text></View>
      </View>

      <Text style={styles.sectionTitle}>Nächstes Ziel</Text>
      <View style={styles.goalCard}>
        <View>
          <Text style={styles.goalTitle}>Grundlagen meistern</Text>
          <Text style={styles.goalText}>Beantworte 20 Übungen richtig.</Text>
        </View>
        <Text style={styles.goalCount}>{Math.min(correct, 20)}/20</Text>
      </View>

      <View style={styles.infoCard}>
        <Text style={styles.infoTitle}>Demnächst</Text>
        <Text style={styles.infoText}>Streak-Kalender, gespeicherte Wörter, schwierige Vokabeln und persönliche Lektionen aus deinen Übersetzungen.</Text>
      </View>
    </ScrollView>
  );
}

export default function App() {
  const [tab, setTab] = useState<Tab>('translate');
  const [points, setPoints] = useState(0);
  const [correct, setCorrect] = useState(0);

  const onCorrect = () => {
    setPoints((p) => p + 10);
    setCorrect((c) => c + 1);
  };

  return (
    <SafeAreaView style={styles.safe}>
      <StatusBar barStyle="light-content" />
      <AppHeader />
      <View style={styles.body}>
        {tab === 'translate' && <TranslateScreen />}
        {tab === 'practice' && <PracticeScreen onCorrect={onCorrect} />}
        {tab === 'progress' && <ProgressScreen points={points} correct={correct} />}
      </View>
      <View style={styles.tabBar}>
        <TouchableOpacity style={styles.tab} onPress={() => setTab('translate')}>
          <Text style={[styles.tabIcon, tab === 'translate' && styles.tabActive]}>⇄</Text>
          <Text style={[styles.tabText, tab === 'translate' && styles.tabActive]}>Übersetzen</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.tab} onPress={() => setTab('practice')}>
          <Text style={[styles.tabIcon, tab === 'practice' && styles.tabActive]}>✦</Text>
          <Text style={[styles.tabText, tab === 'practice' && styles.tabActive]}>Übungen</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.tab} onPress={() => setTab('progress')}>
          <Text style={[styles.tabIcon, tab === 'progress' && styles.tabActive]}>◔</Text>
          <Text style={[styles.tabText, tab === 'progress' && styles.tabActive]}>Fortschritt</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: COLORS.bg },
  header: { height: 72, paddingHorizontal: 20, flexDirection: 'row', alignItems: 'center', borderBottomWidth: 1, borderBottomColor: COLORS.border, backgroundColor: COLORS.bg },
  logoBox: { width: 38, height: 38, borderRadius: 12, backgroundColor: COLORS.red, alignItems: 'center', justifyContent: 'center', marginRight: 11 },
  logoLetter: { color: COLORS.white, fontSize: 23, fontWeight: '900' },
  logo: { color: COLORS.text, fontWeight: '900', fontSize: 20, letterSpacing: 1.8 },
  tagline: { color: COLORS.muted, fontSize: 10, marginTop: 1 },
  body: { flex: 1 },
  screenContent: { paddingHorizontal: 20, paddingTop: 24, paddingBottom: 36 },
  eyebrow: { color: COLORS.red, fontWeight: '800', fontSize: 12, letterSpacing: 1.7, marginBottom: 10 },
  h1: { color: COLORS.text, fontSize: 36, lineHeight: 40, fontWeight: '900', letterSpacing: -1.2 },
  subhead: { color: COLORS.muted, fontSize: 15, lineHeight: 22, marginTop: 9, marginBottom: 24 },
  languageRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 },
  apiKeyRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12, paddingHorizontal: 4 },
  apiKeyStatus: { flex: 1, paddingRight: 12 },
  apiKeyTitle: { color: COLORS.text, fontSize: 13, fontWeight: '800', marginBottom: 3 },
  pill: { flex: 1, borderRadius: 14, paddingVertical: 12, paddingHorizontal: 14, backgroundColor: COLORS.card, borderWidth: 1, borderColor: COLORS.border },
  pillActive: { borderColor: '#3A3A42' },
  pillText: { color: COLORS.muted, fontWeight: '700', textAlign: 'center', fontSize: 13 },
  pillTextActive: { color: COLORS.text },
  swapButton: { width: 48, height: 44, alignItems: 'center', justifyContent: 'center' },
  swapText: { color: COLORS.red, fontSize: 24, fontWeight: '700' },
  card: { backgroundColor: COLORS.card, borderWidth: 1, borderColor: COLORS.border, borderRadius: 20, padding: 18, marginBottom: 14 },
  cardLabel: { color: COLORS.muted, fontWeight: '800', fontSize: 11, letterSpacing: 1.4 },
  input: { color: COLORS.text, minHeight: 104, fontSize: 22, lineHeight: 30, fontWeight: '600', textAlignVertical: 'top', paddingTop: 14 },
  counterRow: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 10 },
  smallMuted: { color: COLORS.muted, fontSize: 12 },
  clear: { color: COLORS.red, fontSize: 12, fontWeight: '700' },
  resultCard: { backgroundColor: '#181315', borderColor: '#48232A' },
  translationError: { color: '#FF8294', fontSize: 13, lineHeight: 19, marginTop: 10 },
  resultTop: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  betaBadge: { backgroundColor: '#3A171E', paddingHorizontal: 9, paddingVertical: 5, borderRadius: 999 },
  betaText: { color: '#FF8294', fontSize: 9, fontWeight: '900', letterSpacing: 0.9 },
  translation: { color: COLORS.text, fontSize: 25, lineHeight: 33, fontWeight: '800', marginTop: 18 },
  dialectHint: { color: '#C8A2A8', marginTop: 14, lineHeight: 19, fontSize: 12 },
  sectionTitle: { color: COLORS.text, fontSize: 17, fontWeight: '800', marginTop: 14, marginBottom: 12 },
  chipsWrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  exampleChip: { backgroundColor: COLORS.card2, borderRadius: 999, borderWidth: 1, borderColor: COLORS.border, paddingHorizontal: 13, paddingVertical: 9 },
  exampleText: { color: COLORS.text, fontSize: 12, fontWeight: '600' },
  infoCard: { backgroundColor: '#111114', borderRadius: 18, borderWidth: 1, borderColor: COLORS.border, padding: 18, marginTop: 24 },
  infoTitle: { color: COLORS.text, fontWeight: '800', fontSize: 15, marginBottom: 7 },
  infoText: { color: COLORS.muted, fontSize: 13, lineHeight: 20 },
  progressTrack: { height: 8, backgroundColor: COLORS.card2, borderRadius: 99, overflow: 'hidden' },
  progressFill: { height: '100%', backgroundColor: COLORS.red, borderRadius: 99 },
  progressMeta: { color: COLORS.muted, fontSize: 11, marginTop: 8, marginBottom: 20 },
  questionCard: { minHeight: 140, justifyContent: 'center' },
  question: { color: COLORS.text, fontSize: 28, lineHeight: 36, fontWeight: '900', marginTop: 14 },
  options: { gap: 10 },
  option: { flexDirection: 'row', alignItems: 'center', padding: 15, borderRadius: 16, borderWidth: 1, borderColor: COLORS.border, backgroundColor: COLORS.card },
  optionCorrect: { borderColor: COLORS.green, backgroundColor: '#10231A' },
  optionWrong: { borderColor: COLORS.red, backgroundColor: '#2A1116' },
  optionIndex: { width: 32, height: 32, borderRadius: 10, textAlign: 'center', textAlignVertical: 'center', lineHeight: 32, overflow: 'hidden', color: COLORS.muted, backgroundColor: COLORS.card2, fontWeight: '900', marginRight: 12 },
  optionText: { color: COLORS.text, fontSize: 15, fontWeight: '700', flex: 1 },
  feedback: { marginTop: 14, padding: 15, borderRadius: 15, borderWidth: 1 },
  feedbackGood: { backgroundColor: '#10231A', borderColor: '#225D40' },
  feedbackBad: { backgroundColor: '#2A1116', borderColor: '#682433' },
  feedbackTitle: { color: COLORS.text, fontSize: 16, fontWeight: '900' },
  feedbackText: { color: COLORS.muted, fontSize: 12, marginTop: 5 },
  primaryButton: { marginTop: 18, backgroundColor: COLORS.red, borderRadius: 16, paddingVertical: 16, alignItems: 'center' },
  buttonDisabled: { opacity: 0.35 },
  primaryButtonText: { color: COLORS.white, fontSize: 15, fontWeight: '900' },
  modalBackdrop: { flex: 1, justifyContent: 'center', alignItems: 'center', padding: 20, backgroundColor: 'rgba(0,0,0,0.78)' },
  modalCard: { width: '100%', maxWidth: 440, backgroundColor: COLORS.card, borderWidth: 1, borderColor: COLORS.border, borderRadius: 20, padding: 20 },
  keyInput: { color: COLORS.text, fontSize: 15, padding: 14, marginTop: 16, borderWidth: 1, borderColor: COLORS.border, borderRadius: 12, backgroundColor: COLORS.bg },
  modalSecondaryButton: { alignItems: 'center', padding: 12 },
  heroStat: { backgroundColor: COLORS.card, borderWidth: 1, borderColor: COLORS.border, borderRadius: 22, padding: 22, alignItems: 'center' },
  heroStatNumber: { color: COLORS.text, fontSize: 54, fontWeight: '900', letterSpacing: -2 },
  heroStatLabel: { color: COLORS.muted, fontSize: 12, marginBottom: 18 },
  levelTrack: { height: 8, width: '100%', backgroundColor: COLORS.card2, borderRadius: 99, overflow: 'hidden', marginBottom: 8 },
  levelFill: { height: '100%', backgroundColor: COLORS.red, borderRadius: 99 },
  statsRow: { flexDirection: 'row', gap: 12, marginTop: 12 },
  statCard: { flex: 1, backgroundColor: COLORS.card, borderWidth: 1, borderColor: COLORS.border, borderRadius: 18, padding: 18 },
  statEmoji: { fontSize: 20 },
  statNumber: { color: COLORS.text, fontSize: 26, fontWeight: '900', marginTop: 10 },
  statLabel: { color: COLORS.muted, fontSize: 11, marginTop: 2 },
  goalCard: { backgroundColor: COLORS.card, borderWidth: 1, borderColor: COLORS.border, borderRadius: 18, padding: 17, flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  goalTitle: { color: COLORS.text, fontSize: 14, fontWeight: '800' },
  goalText: { color: COLORS.muted, fontSize: 11, marginTop: 4 },
  goalCount: { color: COLORS.red, fontSize: 18, fontWeight: '900' },
  tabBar: { height: 78, flexDirection: 'row', borderTopWidth: 1, borderTopColor: COLORS.border, backgroundColor: '#0E0E10', paddingTop: 10 },
  tab: { flex: 1, alignItems: 'center' },
  tabIcon: { color: COLORS.muted, fontSize: 21, fontWeight: '800', height: 28 },
  tabText: { color: COLORS.muted, fontSize: 10, fontWeight: '700', marginTop: 2 },
  tabActive: { color: COLORS.red },
});

