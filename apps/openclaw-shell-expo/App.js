import React, { useMemo, useState } from 'react';
import { SafeAreaView, View, Text, TextInput, Pressable, ScrollView, StyleSheet } from 'react-native';

const seedFiles = [{ id: 'file-1', name: 'notes.md', content: '# OpenClaw Expo shell\n\nThis is the Expo Go starter.' }];
const seedModels = [{ id: 'model-1', name: 'Placeholder runtime', modelId: 'placeholder-runtime' }];
const seedMessages = [{ id: 'msg-1', role: 'assistant', content: 'OpenClaw Expo shell is ready.' }];

const makeId = (prefix) => `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;

function Tab({ label, active, onPress }) {
  return (
    <Pressable onPress={onPress} style={[styles.tab, active && styles.tabActive]}>
      <Text style={[styles.tabText, active && styles.tabTextActive]}>{label}</Text>
    </Pressable>
  );
}

export default function App() {
  const [tab, setTab] = useState('Chat');
  const [models, setModels] = useState(seedModels);
  const [files, setFiles] = useState(seedFiles);
  const [messages, setMessages] = useState(seedMessages);
  const [selectedModelId, setSelectedModelId] = useState(seedModels[0].id);
  const [selectedFileId, setSelectedFileId] = useState(seedFiles[0].id);
  const [modelName, setModelName] = useState('');
  const [scratchName, setScratchName] = useState('');
  const [scratchContent, setScratchContent] = useState('');
  const [prompt, setPrompt] = useState('');

  const selectedModel = useMemo(() => models.find((x) => x.id === selectedModelId), [models, selectedModelId]);
  const selectedFile = useMemo(() => files.find((x) => x.id === selectedFileId), [files, selectedFileId]);

  const addModel = () => {
    const name = modelName.trim();
    if (!name) return;
    const next = { id: makeId('model'), name, modelId: name.toLowerCase().replace(/\s+/g, '-') };
    setModels((current) => [next, ...current]);
    setSelectedModelId(next.id);
    setModelName('');
  };

  const addScratchFile = () => {
    const name = scratchName.trim();
    if (!name) return;
    const next = { id: makeId('file'), name, content: scratchContent };
    setFiles((current) => [next, ...current]);
    setSelectedFileId(next.id);
    setScratchName('');
    setScratchContent('');
  };

  const updateSelectedFile = (nextContent) => {
    if (!selectedFile) return;
    setFiles((current) => current.map((item) => item.id === selectedFile.id ? { ...item, content: nextContent } : item));
  };

  const send = () => {
    const text = prompt.trim();
    if (!text) return;
    const user = { id: makeId('msg-user'), role: 'user', content: text };
    const assistant = {
      id: makeId('msg-assistant'),
      role: 'assistant',
      content: `Expo starter reply.\n\nModel: ${selectedModel?.modelId ?? 'none'}\nFile: ${selectedFile?.name ?? 'none'}\n\nThis path is Expo Go runnable today. True on-device local inference still belongs to the native runtime path or a later EAS dev build with native modules.`
    };
    setMessages((current) => [...current, user, assistant]);
    setPrompt('');
  };

  return (
    <SafeAreaView style={styles.safeArea}>
      <View style={styles.header}>
        <Text style={styles.title}>OpenClaw Shell Expo</Text>
        <Text style={styles.subtitle}>Expo Go runnable companion</Text>
      </View>

      <View style={styles.tabs}>
        {['Models', 'Chat', 'Files', 'Editor'].map((label) => (
          <Tab key={label} label={label} active={tab === label} onPress={() => setTab(label)} />
        ))}
      </View>

      {tab === 'Models' && (
        <ScrollView contentContainerStyle={styles.content}>
          <Text style={styles.note}>Pure JS Expo shell for fast iteration. The local LLM runtime still needs native integration later.</Text>
          <TextInput style={styles.input} placeholder="Model display name" placeholderTextColor="#7f8aa3" value={modelName} onChangeText={setModelName} />
          <Pressable style={styles.button} onPress={addModel}><Text style={styles.buttonText}>Add model</Text></Pressable>
          {models.map((item) => (
            <Pressable key={item.id} style={[styles.card, item.id === selectedModelId && styles.cardActive]} onPress={() => setSelectedModelId(item.id)}>
              <Text style={styles.cardTitle}>{item.name}</Text>
              <Text style={styles.cardMeta}>{item.modelId}</Text>
            </Pressable>
          ))}
        </ScrollView>
      )}

      {tab === 'Files' && (
        <ScrollView contentContainerStyle={styles.content}>
          <TextInput style={styles.input} placeholder="Scratch file name" placeholderTextColor="#7f8aa3" value={scratchName} onChangeText={setScratchName} />
          <TextInput style={[styles.input, styles.bigInput]} placeholder="Scratch file contents" placeholderTextColor="#7f8aa3" multiline value={scratchContent} onChangeText={setScratchContent} />
          <Pressable style={styles.button} onPress={addScratchFile}><Text style={styles.buttonText}>Create scratch file</Text></Pressable>
          {files.map((item) => (
            <Pressable key={item.id} style={[styles.card, item.id === selectedFileId && styles.cardActive]} onPress={() => setSelectedFileId(item.id)}>
              <Text style={styles.cardTitle}>{item.name}</Text>
              <Text style={styles.cardMeta}>{item.content.slice(0, 100) || 'Empty file'}</Text>
            </Pressable>
          ))}
        </ScrollView>
      )}

      {tab === 'Chat' && (
        <View style={styles.flex}>
          <ScrollView contentContainerStyle={styles.content}>
            {messages.map((item) => (
              <View key={item.id} style={styles.card}>
                <Text style={styles.cardMeta}>{item.role.toUpperCase()}</Text>
                <Text style={styles.message}>{item.content}</Text>
              </View>
            ))}
          </ScrollView>
          <View style={styles.composer}>
            <Text style={styles.cardMeta}>Model: {selectedModel?.modelId ?? 'none'} • File: {selectedFile?.name ?? 'none'}</Text>
            <TextInput style={[styles.input, styles.bigInput]} placeholder="Ask the shell" placeholderTextColor="#7f8aa3" multiline value={prompt} onChangeText={setPrompt} />
            <Pressable style={styles.button} onPress={send}><Text style={styles.buttonText}>Send</Text></Pressable>
          </View>
        </View>
      )}

      {tab === 'Editor' && (
        <ScrollView contentContainerStyle={styles.content}>
          <Text style={styles.note}>{selectedFile ? `Editing ${selectedFile.name}` : 'Select a file first.'}</Text>
          <TextInput style={[styles.input, styles.editor]} multiline value={selectedFile?.content ?? ''} onChangeText={updateSelectedFile} editable={!!selectedFile} />
        </ScrollView>
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: { flex: 1, backgroundColor: '#0f1115' },
  flex: { flex: 1 },
  header: { paddingHorizontal: 16, paddingTop: 16, paddingBottom: 8 },
  title: { color: '#f6f8fc', fontSize: 24, fontWeight: '700' },
  subtitle: { color: '#94a0bb', marginTop: 4 },
  tabs: { flexDirection: 'row', gap: 8, paddingHorizontal: 12, paddingBottom: 12 },
  tab: { flex: 1, paddingVertical: 10, borderRadius: 12, backgroundColor: '#171c25', borderWidth: 1, borderColor: '#263043', alignItems: 'center' },
  tabActive: { backgroundColor: '#2b5cff', borderColor: '#2b5cff' },
  tabText: { color: '#d7deef', fontWeight: '600' },
  tabTextActive: { color: '#fff' },
  content: { padding: 16, gap: 12, paddingBottom: 24 },
  note: { color: '#c8cfe0', lineHeight: 20 },
  input: { backgroundColor: '#10141c', color: '#f6f8fc', borderWidth: 1, borderColor: '#263043', borderRadius: 12, paddingHorizontal: 12, paddingVertical: 10 },
  bigInput: { minHeight: 92, textAlignVertical: 'top' },
  editor: { minHeight: 320, textAlignVertical: 'top' },
  button: { backgroundColor: '#2b5cff', borderRadius: 12, paddingVertical: 12, alignItems: 'center' },
  buttonText: { color: '#fff', fontWeight: '700' },
  card: { backgroundColor: '#171c25', borderRadius: 14, borderWidth: 1, borderColor: '#263043', padding: 12, gap: 6 },
  cardActive: { borderColor: '#2b5cff' },
  cardTitle: { color: '#f6f8fc', fontWeight: '700' },
  cardMeta: { color: '#94a0bb' },
  message: { color: '#f6f8fc', lineHeight: 20 },
  composer: { padding: 16, gap: 10, borderTopWidth: 1, borderTopColor: '#263043', backgroundColor: '#0f1115' }
});
