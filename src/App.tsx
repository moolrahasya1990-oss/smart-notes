import React, { useState, useEffect } from 'react';
import { 
  Search, 
  Grid, 
  List, 
  Settings, 
  FolderClosed, 
  Plus, 
  Pin, 
  Star, 
  Copy, 
  Trash2, 
  Lock, 
  Unlock, 
  FileText, 
  ChevronRight, 
  Info, 
  Sun, 
  Moon, 
  RefreshCw, 
  ArrowLeft, 
  Check, 
  Folder,
  Eye,
  FileCheck
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

// Design matching Flutter's color swatches
const NOTE_COLORS = [
  { value: 0xFFFFFFFF, hex: '#ffffff', textColor: 'text-slate-800' },
  { value: 0xfffecaca, hex: '#fecaca', textColor: 'text-red-950' },
  { value: 0xfffed7aa, hex: '#fed7aa', textColor: 'text-amber-950' },
  { value: 0xfffef08a, hex: '#fef08a', textColor: 'text-yellow-950' },
  { value: 0xffbbf7d0, hex: '#bbf7d0', textColor: 'text-green-950' },
  { value: 0xff99f6e4, hex: '#99f6e4', textColor: 'text-teal-950' },
  { value: 0xffbfdbfe, hex: '#bfdbfe', textColor: 'text-blue-950' },
  { value: 0xffe9d5ff, hex: '#e9d5ff', textColor: 'text-purple-950' },
  { value: 0xfffbcfe8, hex: '#fbcfe8', textColor: 'text-pink-950' },
];

interface Note {
  id: string;
  title: string;
  content: string;
  createdAt: string;
  updatedAt: string;
  colorValue: number;
  categoryName: string;
  isPinned: boolean;
  isFavorite: boolean;
}

const DEFAULT_CATEGORIES = ['Personal', 'Work', 'Study', 'Ideas', 'Shopping'];

export default function App() {
  // --- Persistent Local States ---
  const [notes, setNotes] = useState<Note[]>(() => {
    const saved = localStorage.getItem('smart_notes_data');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {
        return [];
      }
    }
    // Default initial seed
    return [
      {
        id: 'sample-1',
        title: '💡 App Development Ideas',
        content: '- Design layout in Flutter using M3 components\n- Add Hive database for fast local disk access\n- Complete Riverpod state management implementation\n- Add a bio passcode face ID lock screen',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        colorValue: 0xffbfdbfe,
        categoryName: 'Ideas',
        isPinned: true,
        isFavorite: true,
      },
      {
        id: 'sample-2',
        title: '🛒 Weekly grocery lists',
        content: '- Apple cider vinegar\n- Greek yogurt (plain)\n- Fresh strawberries and avocados\n- Dark unsweetened chocolates',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        colorValue: 0xfffef08a,
        categoryName: 'Shopping',
        isPinned: false,
        isFavorite: false,
      }
    ];
  });

  const [categories, setCategories] = useState<string[]>(() => {
    const saved = localStorage.getItem('smart_categories_data');
    if (saved) {
      try { return JSON.parse(saved); } catch (e) {}
    }
    return DEFAULT_CATEGORIES;
  });

  const [darkMode, setDarkMode] = useState<boolean>(() => {
    return localStorage.getItem('smart_dark_mode') === 'true';
  });

  const [securityPin, setSecurityPin] = useState<string | null>(() => {
    return localStorage.getItem('smart_security_pin') || null;
  });

  // --- Active Session States ---
  const [isLocked, setIsLocked] = useState<boolean>(() => {
    // If a PIN is configured, lock screen automatically on initial mount
    return !!localStorage.getItem('smart_security_pin');
  });
  const [pinEntry, setPinEntry] = useState<string>('');
  const [lockScreenStatus, setLockScreenStatus] = useState<string>('Enter PIN to Unlock');
  const [isSettingPin, setIsSettingPin] = useState<boolean>(false);
  const [tempNewPin, setTempNewPin] = useState<string | null>(null);

  const [currentView, setCurrentView] = useState<'list' | 'editor' | 'settings' | 'categories' | 'migration'>('list');
  const [isGridView, setIsGridView] = useState<boolean>(true);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);

  // --- Editor States ---
  const [editorId, setEditorId] = useState<string | null>(null);
  const [editorTitle, setEditorTitle] = useState<string>('');
  const [editorContent, setEditorContent] = useState<string>('');
  const [editorCategory, setEditorCategory] = useState<string>('Personal');
  const [editorColor, setEditorColor] = useState<number>(0xFFFFFFFF);
  const [editorIsPinned, setEditorIsPinned] = useState<boolean>(false);
  const [editorIsFavorite, setEditorIsFavorite] = useState<boolean>(false);
  
  // Custom states for dialogs & inputs
  const [tempCategoryInput, setTempCategoryInput] = useState<string>('');
  const [showAddCategoryModal, setShowAddCategoryModal] = useState<boolean>(false);
  const [jsonInput, setJsonInput] = useState<string>('');
  const [syncStatus, setSyncStatus] = useState<string>('Synced');

  // --- Persistence Sync Effects ---
  useEffect(() => {
    localStorage.setItem('smart_notes_data', JSON.stringify(notes));
  }, [notes]);

  useEffect(() => {
    localStorage.setItem('smart_categories_data', JSON.stringify(categories));
  }, [categories]);

  useEffect(() => {
    localStorage.setItem('smart_dark_mode', String(darkMode));
    if (darkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [darkMode]);

  useEffect(() => {
    if (securityPin) {
      localStorage.setItem('smart_security_pin', securityPin);
    } else {
      localStorage.removeItem('smart_security_pin');
    }
  }, [securityPin]);

  // Real-time editor stats & auto-save trigger
  const wordCount = editorContent.trim() === '' ? 0 : editorContent.trim().split(/\s+/).length;
  const charCount = editorContent.length;

  useEffect(() => {
    if (currentView !== 'editor') return;
    
    // Auto-save debouncer
    setSyncStatus('Drafting...');
    const timer = setTimeout(() => {
      saveActiveNote(true);
    }, 1200);

    return () => clearTimeout(timer);
  }, [editorTitle, editorContent, editorCategory, editorColor, editorIsPinned, editorIsFavorite]);

  // --- Business Logic ---
  const openNoteInEditor = (note: Note) => {
    setEditorId(note.id);
    setEditorTitle(note.title);
    setEditorContent(note.content);
    setEditorCategory(note.categoryName);
    setEditorColor(note.colorValue);
    setEditorIsPinned(note.isPinned);
    setEditorIsFavorite(note.isFavorite);
    setSyncStatus('Synced');
    setCurrentView('editor');
  };

  const startNewNote = () => {
    setEditorId(null);
    setEditorTitle('');
    setEditorContent('');
    setEditorCategory(selectedCategory || 'Personal');
    setEditorColor(0xFFFFFFFF);
    setEditorIsPinned(false);
    setEditorIsFavorite(false);
    setSyncStatus('Drafting');
    setCurrentView('editor');
  };

  const saveActiveNote = (isAuto = false) => {
    if (isAuto && !editorTitle.trim() && !editorContent.trim() && !editorId) {
      return; // Do not auto-save a completely blank new entry
    }

    const nowStr = new Date().toISOString();
    
    if (editorId) {
      // Edit existing note
      setNotes(prev => prev.map(n => {
        if (n.id === editorId) {
          return {
            ...n,
            title: editorTitle,
            content: editorContent,
            categoryName: editorCategory,
            colorValue: editorColor,
            isPinned: editorIsPinned,
            isFavorite: editorIsFavorite,
            updatedAt: nowStr
          };
        }
        return n;
      }));
    } else {
      // Create new note
      const newId = String(Date.now());
      const newNote: Note = {
        id: newId,
        title: editorTitle || 'Untitled Note',
        content: editorContent,
        categoryName: editorCategory,
        colorValue: editorColor,
        isPinned: editorIsPinned,
        isFavorite: editorIsFavorite,
        createdAt: nowStr,
        updatedAt: nowStr
      };
      setNotes(prev => [newNote, ...prev]);
      setEditorId(newId); // Keep active ID to avoid multiple duplicate draft creation
    }
    setSyncStatus('Synced');
  };

  const deleteNote = (id: string, event?: React.MouseEvent) => {
    if (event) event.stopPropagation();
    if (confirm('Are you sure you want to delete this note?')) {
      setNotes(prev => prev.filter(n => n.id !== id));
      if (currentView === 'editor' && editorId === id) {
        setCurrentView('list');
      }
    }
  };

  const duplicateNote = (note: Note, event?: React.MouseEvent) => {
    if (event) event.stopPropagation();
    const nowStr = new Date().toISOString();
    const duplicated: Note = {
      ...note,
      id: String(Date.now()),
      title: `${note.title} (Copy)`,
      isPinned: false,
      createdAt: nowStr,
      updatedAt: nowStr
    };
    setNotes(prev => [duplicated, ...prev]);
  };

  const togglePinStatus = (id: string, event?: React.MouseEvent) => {
    if (event) event.stopPropagation();
    setNotes(prev => prev.map(n => n.id === id ? { ...n, isPinned: !n.isPinned } : n));
  };

  const toggleFavoriteStatus = (id: string, event?: React.MouseEvent) => {
    if (event) event.stopPropagation();
    setNotes(prev => prev.map(n => n.id === id ? { ...n, isFavorite: !n.isFavorite } : n));
  };

  // --- Category Logic ---
  const addCustomCategory = () => {
    const trimmed = tempCategoryInput.trim();
    if (!trimmed) return;
    if (categories.some(c => c.toLowerCase() === trimmed.toLowerCase())) {
      alert('This category category name already exists.');
      return;
    }
    setCategories(prev => [...prev, trimmed]);
    setTempCategoryInput('');
    setShowAddCategoryModal(false);
  };

  const removeCategory = (name: string) => {
    if (DEFAULT_CATEGORIES.some(c => c.toLowerCase() === name.toLowerCase())) {
      alert('System categories are protected and cannot be deleted.');
      return;
    }
    if (confirm(`Are you sure you want to delete "${name}"? Notes in this category will shift to Personal.`)) {
      setCategories(prev => prev.filter(c => c !== name));
      setNotes(prev => prev.map(n => n.categoryName === name ? { ...n, categoryName: 'Personal' } : n));
      if (selectedCategory === name) {
        setSelectedCategory(null);
      }
    }
  };

  // --- PIN Keyboard Authentication Handlers ---
  const handlePinKeyPress = (val: string) => {
    if (pinEntry.length < 4) {
      const nextPin = pinEntry + val;
      setPinEntry(nextPin);

      if (nextPin.length === 4) {
        setTimeout(() => {
          if (isSettingPin) {
            // Setting a PIN flow
            if (!tempNewPin) {
              setTempNewPin(nextPin);
              setPinEntry('');
              setLockScreenStatus('Confirm your 4-Digit Passcode');
            } else {
              if (tempNewPin === nextPin) {
                setSecurityPin(nextPin);
                setIsLocked(false);
                setIsSettingPin(false);
                setTempNewPin(null);
                setPinEntry('');
                setLockScreenStatus('Enter PIN to Unlock');
                alert('Secure passcode lock enabled successfully!');
                setCurrentView('settings');
              } else {
                setPinEntry('');
                setTempNewPin(null);
                setLockScreenStatus('PIN mismatch. Create passcode');
              }
            }
          } else {
            // Unlocking flow
            if (securityPin === nextPin) {
              setIsLocked(false);
              setPinEntry('');
              setLockScreenStatus('Enter PIN to Unlock');
              setCurrentView('list');
            } else {
              setPinEntry('');
              setLockScreenStatus('Incorrect PIN. Try Again');
            }
          }
        }, 150);
      }
    }
  };

  const handlePinBackspace = () => {
    if (pinEntry.length > 0) {
      setPinEntry(prev => prev.substring(0, prev.length - 1));
    }
  };

  const triggerMockBiometrics = () => {
    if (isSettingPin) return;
    setIsLocked(false);
    setPinEntry('');
    alert('🔐 Unlocked securely via integrated FaceID/Fingerprint biometric simulation.');
    setCurrentView('list');
  };

  // --- Migration Handlers ---
  const handleImportJson = () => {
    try {
      const parsed = JSON.parse(jsonInput);
      if (parsed.app !== 'SmartNotes') {
        throw new Error('Not a valid Smart Notes migration block');
      }
      
      if (parsed.categories) setCategories(parsed.categories);
      if (parsed.notes) setNotes(parsed.notes);
      
      setJsonInput('');
      alert('Data restored successfully! All notes and settings have been synced.');
      setCurrentView('list');
    } catch (e: any) {
      alert(`Failed to restore backup: ${e?.message || 'Invalid JSON format'}`);
    }
  };

  const loadSampleDemoData = () => {
    const demoPayload = {
      app: 'SmartNotes',
      version: 1,
      categories: ['Personal', 'Work', 'Study', 'Shopping', 'Travel'],
      notes: [
        {
          id: 'sample-1',
          title: '💡 Flutter Dev checklist',
          content: '- Write clean repository contracts in domain folder\n- Initialize Hive locally in main.dart\n- Implement StateNotifier with Riverpod for robust note triggers\n- Bind FaceID permissions in AndroidManifest & Info.plist',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          colorValue: 0xffbfdbfe,
          categoryName: 'Ideas',
          isPinned: true,
          isFavorite: true,
        },
        {
          id: 'sample-2',
          title: '🛒 Grocery checklist items',
          content: '- Fresh whole organic avocados\n- Sugar-free Greek yogurt\n- Whole wheat sourdough bread\n- Sparkling mineral water',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          colorValue: 0xfffef08a,
          categoryName: 'Shopping',
          isPinned: false,
          isFavorite: false,
        },
        {
          id: 'sample-3',
          title: '📖 Smart Notes Philosophy',
          content: 'Keep simple tools simple. Minimize infrastructure overlays. Maximize legibility, focus, design spacing and local privacy first.',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
          colorValue: 0xfffbcfe8,
          categoryName: 'Personal',
          isPinned: false,
          isFavorite: true,
        }
      ]
    };

    setCategories(demoPayload.categories);
    setNotes(demoPayload.notes);
    alert('Sample demo seeds loaded perfectly. Have fun exploring!');
    setCurrentView('list');
  };

  // --- Filters and Display Sorting ---
  const filteredNotes = notes.filter(n => {
    const matchesCategory = selectedCategory ? n.categoryName === selectedCategory : true;
    const matchesSearch = searchQuery 
      ? n.title.toLowerCase().includes(searchQuery.toLowerCase()) || 
        n.content.toLowerCase().includes(searchQuery.toLowerCase())
      : true;
    return matchesCategory && matchesSearch;
  });

  // Sort: pinned first, then descending by updatedAt
  const sortedNotes = [...filteredNotes].sort((a, b) => {
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;
    return new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime();
  });

  // --- Lock Screen Render Guard ---
  if (isLocked) {
    return (
      <div className={`min-h-screen ${darkMode ? 'dark bg-slate-950 text-slate-100' : 'bg-slate-50 text-slate-800'} flex flex-col justify-between p-6 transition-colors duration-300`}>
        <div className="flex-1 flex flex-col items-center justify-center">
          <div className="p-4 rounded-3xl bg-blue-600/10 text-blue-600 dark:text-blue-400 mb-4 animate-bounce">
            {isSettingPin ? <Unlock className="w-12 h-12" /> : <Lock className="w-12 h-12" />}
          </div>
          <h1 className="text-xl font-bold mb-2">{lockScreenStatus}</h1>
          
          {/* PIN circles */}
          <div className="flex gap-4 justify-center my-6">
            {[0, 1, 2, 3].map((idx) => (
              <div
                key={idx}
                className={`w-4.5 h-4.5 rounded-full border-2 border-blue-600 transition-all duration-150 ${
                  idx < pinEntry.length ? 'bg-blue-600 scale-110' : 'bg-transparent'
                }`}
              />
            ))}
          </div>
        </div>

        {/* Numpad Keyboard */}
        <div className="max-w-xs mx-auto w-full mb-12">
          <div className="grid grid-cols-3 gap-4">
            {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((num) => (
              <button
                key={num}
                id={`pin_key_${num}`}
                onClick={() => handlePinKeyPress(num)}
                className="h-16 rounded-full text-xl font-bold bg-white dark:bg-slate-900 border border-slate-100 dark:border-slate-800 shadow-xs hover:bg-slate-100 dark:hover:bg-slate-800 active:scale-95 transition-all"
              >
                {num}
              </button>
            ))}
            
            {/* Action Row */}
            <button
              id="pin_key_bio"
              onClick={triggerMockBiometrics}
              disabled={isSettingPin}
              className={`h-16 rounded-full flex items-center justify-center bg-blue-50 dark:bg-blue-950/40 text-blue-600 dark:text-blue-400 hover:bg-blue-100 dark:hover:bg-blue-900/40 ${isSettingPin ? 'opacity-20 cursor-not-allowed' : ''}`}
            >
              <Eye className="w-6 h-6" />
            </button>
            <button
              id="pin_key_0"
              onClick={() => handlePinKeyPress('0')}
              className="h-16 rounded-full text-xl font-bold bg-white dark:bg-slate-900 border border-slate-100 dark:border-slate-800 shadow-xs hover:bg-slate-100 dark:hover:bg-slate-800 active:scale-95 transition-all"
            >
              0
            </button>
            <button
              id="pin_key_back"
              onClick={handlePinBackspace}
              className="h-16 rounded-full flex items-center justify-center bg-slate-100 dark:bg-slate-900 hover:bg-slate-200 dark:hover:bg-slate-800 text-slate-500"
            >
              Back
            </button>
          </div>

          {isSettingPin && (
            <button
              id="pin_key_cancel"
              onClick={() => {
                setIsSettingPin(false);
                setIsLocked(false);
                setPinEntry('');
                setTempNewPin(null);
                setCurrentView('settings');
              }}
              className="w-full mt-6 text-center text-sm font-semibold text-blue-600 hover:underline"
            >
              Cancel Setup
            </button>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className={`min-h-screen ${darkMode ? 'dark bg-[#090d16] text-[#f8fafc]' : 'bg-[#f8fafc] text-[#0f172a]'} font-sans flex flex-col transition-colors duration-200`}>
      
      {/* --- WEB APP PREVIEW HEADER --- */}
      <header className="sticky top-0 z-40 bg-white/80 dark:bg-slate-900/80 backdrop-blur-md border-b border-slate-200 dark:border-slate-800 px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-9 h-9 bg-blue-600 rounded-xl flex items-center justify-center text-white">
            <FileText className="w-5 h-5" />
          </div>
          <div>
            <h1 className="font-bold text-base leading-none">Smart Notes</h1>
            <span className="text-[10px] text-blue-500 font-semibold tracking-wider uppercase">Flutter Blueprint Simulator</span>
          </div>
        </div>

        <div className="flex items-center gap-1">
          <button
            id="theme_toggle_btn"
            onClick={() => setDarkMode(!darkMode)}
            className="p-1 px-2.5 rounded-lg border border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 flex items-center gap-1.5 text-xs transition duration-150"
          >
            {darkMode ? <Sun className="w-3.5 h-3.5 text-yellow-400" /> : <Moon className="w-3.5 h-3.5 text-blue-600" />}
            <span className="hidden sm:inline">{darkMode ? 'Light' : 'Dark'}</span>
          </button>

          {securityPin && (
            <button
              id="security_lock_now"
              onClick={() => setIsLocked(true)}
              className="p-1.5 rounded-lg border border-slate-200 dark:border-slate-800 text-red-500 hover:bg-red-50 dark:hover:bg-red-950/20"
              title="Lock Application Now"
            >
              <Lock className="w-3.5 h-3.5" />
            </button>
          )}
        </div>
      </header>

      {/* --- WORKSPACE BODY CONTAINER --- */}
      <main className="flex-1 w-full max-w-2xl mx-auto px-4 py-4 mb-20">
        
        {/* VIEW 1: NOTE GRID & LIST DASHBOARD */}
        {currentView === 'list' && (
          <div className="flex flex-col gap-4">
            
            {/* Search inputs */}
            <div className="relative w-full">
              <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4.5 h-4.5 text-slate-400" />
              <input
                id="search_box_input"
                type="text"
                placeholder="Search by title or content..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-10 py-3 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl outline-none focus:ring-2 focus:ring-blue-500 text-sm shadow-xs transition"
              />
              {searchQuery && (
                <button 
                  id="search_clear_btn"
                  onClick={() => setSearchQuery('')}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-xs font-semibold text-slate-400 hover:text-slate-600"
                >
                  Clear
                </button>
              )}
            </div>

            {/* Horizontal Categories tags row */}
            <div className="flex items-center gap-1.5 overflow-x-auto pb-1 scrollbar-none">
              <button
                id="cat_chip_all"
                onClick={() => setSelectedCategory(null)}
                className={`px-3.5 py-1.5 text-xs font-semibold rounded-full shrink-0 transition-all ${
                  selectedCategory === null 
                    ? 'bg-blue-600 text-white' 
                    : 'bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300'
                }`}
              >
                All
              </button>
              {categories.map((cat) => (
                <button
                  key={cat}
                  id={`cat_chip_${cat.toLowerCase()}`}
                  onClick={() => setSelectedCategory(cat)}
                  className={`px-3.5 py-1.5 text-xs font-semibold rounded-full shrink-0 transition-all ${
                    selectedCategory === cat 
                      ? 'bg-blue-600 text-white' 
                      : 'bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-slate-600 dark:text-slate-300'
                  }`}
                >
                  {cat}
                </button>
              ))}
            </div>

            {/* Layout Toggles and Statistics count */}
            <div className="flex items-center justify-between text-xs text-slate-500 mt-1">
              <span>{sortedNotes.length} notes found</span>
              <button
                id="layout_toggle_view"
                onClick={() => setIsGridView(!isGridView)}
                className="flex items-center gap-1 text-blue-500 font-semibold"
              >
                {isGridView ? <List className="w-3.5 h-3.5" /> : <Grid className="w-3.5 h-3.5" />}
                <span>{isGridView ? 'List Layout' : 'Grid Layout'}</span>
              </button>
            </div>

            {/* Notes collection Container */}
            {sortedNotes.length === 0 ? (
              <div className="flex flex-col items-center justify-center p-12 text-center bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl mt-2">
                <FolderClosed className="w-16 h-16 text-slate-300 dark:text-slate-700 mb-3" />
                <h3 className="font-semibold text-slate-700 dark:text-slate-200">No Notes Available</h3>
                <p className="text-xs text-slate-400 mt-1 max-w-xs">Create your first offline note using the "+ Create Note" floating button below.</p>
              </div>
            ) : (
              <div className={isGridView ? 'grid grid-cols-2 gap-3.5 mt-1' : 'flex flex-col gap-3 mt-1'}>
                {sortedNotes.map((note) => {
                  const specColor = NOTE_COLORS.find(c => c.value === note.colorValue) || NOTE_COLORS[0];
                  return (
                    <motion.div
                      layoutId={note.id}
                      key={note.id}
                      id={`note_card_${note.id}`}
                      onClick={() => openNoteInEditor(note)}
                      className={`p-4 rounded-3xl border transition-all duration-200 cursor-pointer relative flex flex-col justify-between ${
                        note.colorValue === 0xFFFFFFFF 
                          ? 'bg-white dark:bg-[#151e2e] border-slate-200 dark:border-slate-850 hover:shadow-md' 
                          : 'border-slate-300 hover:brightness-95'
                      }`}
                      style={{ 
                        backgroundColor: note.colorValue !== 0xFFFFFFFF ? specColor.hex : undefined,
                        color: note.colorValue !== 0xFFFFFFFF ? '#0f172a' : undefined
                      }}
                    >
                      <div>
                        <div className="flex items-start justify-between gap-1">
                          <h4 className="font-bold text-sm line-clamp-1 flex-1">
                            {note.title || 'Untitled Note'}
                          </h4>
                          <div className="flex gap-1 shrink-0">
                            {note.isPinned && <Pin className="w-3.5 h-3.5 text-amber-500 fill-amber-500" />}
                            {note.isFavorite && <Star className="w-3.5 h-3.5 text-indigo-500 fill-indigo-500" />}
                          </div>
                        </div>
                        <p className={`text-xs mt-2 line-clamp-4 leading-relaxed ${note.colorValue !== 0xFFFFFFFF ? 'text-slate-800' : 'text-slate-500'}`}>
                          {note.content}
                        </p>
                      </div>

                      <div className="flex items-center justify-between mt-4 text-[10px] font-semibold border-t pt-2 border-black/5 dark:border-white/5">
                        <span className={`px-2 py-0.5 rounded-full ${note.colorValue !== 0xFFFFFFFF ? 'bg-black/10' : 'bg-blue-50 dark:bg-slate-800 text-blue-500'}`}>
                          {note.categoryName}
                        </span>
                        <span className={note.colorValue !== 0xFFFFFFFF ? 'text-slate-600' : 'text-slate-400'}>
                          {new Date(note.updatedAt).toLocaleDateString()}
                        </span>
                      </div>
                    </motion.div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* VIEW 2: NOTE COMPOSER EDITOR */}
        {currentView === 'editor' && (
          <div className="flex flex-col gap-4 animate-fade-in">
            <div className="flex items-center justify-between">
              <button
                id="editor_back_btn"
                onClick={() => {
                  saveActiveNote();
                  setCurrentView('list');
                }}
                className="flex items-center gap-1.5 text-xs font-semibold text-blue-500"
              >
                <ArrowLeft className="w-4 h-4" />
                <span>Save & Back</span>
              </button>
              
              <div className="flex gap-1.5">
                <button
                  id="editor_pin_btn"
                  onClick={() => setEditorIsPinned(!editorIsPinned)}
                  className={`p-1.5 rounded-xl border ${editorIsPinned ? 'bg-amber-500/10 border-amber-500 text-amber-500' : 'border-slate-200 dark:border-slate-800'}`}
                  title="Pin Note"
                >
                  <Pin className="w-4 h-4" />
                </button>
                <button
                  id="editor_fav_btn"
                  onClick={() => setEditorIsFavorite(!editorIsFavorite)}
                  className={`p-1.5 rounded-xl border ${editorIsFavorite ? 'bg-indigo-500/10 border-indigo-500 text-indigo-500' : 'border-slate-200 dark:border-slate-800'}`}
                  title="Favorite Note"
                >
                  <Star className="w-4 h-4" />
                </button>
                <button
                  id="editor_dup_btn"
                  onClick={() => {
                    const activeN: Note = {
                      id: editorId || '',
                      title: editorTitle,
                      content: editorContent,
                      categoryName: editorCategory,
                      colorValue: editorColor,
                      isPinned: editorIsPinned,
                      isFavorite: editorIsFavorite,
                      createdAt: '',
                      updatedAt: ''
                    };
                    duplicateNote(activeN);
                    alert('Note duplicated as copy draft.');
                  }}
                  className="p-1.5 rounded-xl border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800"
                  title="Duplicate Draft"
                >
                  <Copy className="w-4 h-4" />
                </button>
                {editorId && (
                  <button
                    id="editor_del_btn"
                    onClick={() => deleteNote(editorId)}
                    className="p-1.5 rounded-xl border border-red-200 text-red-500 hover:bg-red-50 dark:hover:bg-red-950/20"
                    title="Delete Note"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
              </div>
            </div>

            {/* Note composition card */}
            <div 
              className={`p-6 rounded-3xl border transition-colors duration-200 ${
                editorColor === 0xFFFFFFFF 
                  ? 'bg-white dark:bg-slate-900 border-slate-200 dark:border-slate-850' 
                  : 'border-slate-300'
              }`}
              style={{ 
                backgroundColor: editorColor !== 0xFFFFFFFF ? NOTE_COLORS.find(c => c.value === editorColor)?.hex : undefined 
              }}
            >
              {/* Category dropdown within composer */}
              <div className="mb-4">
                <select
                  id="editor_category_select"
                  value={editorCategory}
                  onChange={(e) => setEditorCategory(e.target.value)}
                  className={`px-3 py-1.5 text-xs font-semibold rounded-xl border outline-none ${
                    editorColor !== 0xFFFFFFFF 
                      ? 'bg-black/15 text-[#0f172a] border-none' 
                      : 'bg-white dark:bg-slate-850 text-slate-700 dark:text-slate-200 border-slate-200 dark:border-slate-800'
                  }`}
                >
                  {categories.map((cat) => (
                    <option key={cat} value={cat}>{cat}</option>
                  ))}
                </select>
              </div>

              {/* Title Input */}
              <input
                id="editor_title_input"
                type="text"
                placeholder="Note Title"
                maxLength={80}
                value={editorTitle}
                onChange={(e) => setEditorTitle(e.target.value)}
                className={`w-full text-xl font-bold bg-transparent outline-none pb-2 border-b border-black/5 dark:border-white/5 ${
                  editorColor !== 0xFFFFFFFF ? 'text-slate-900 placeholder:text-slate-500' : 'text-slate-900 dark:text-white placeholder:text-slate-400'
                }`}
              />

              {/* Content text Area */}
              <textarea
                id="editor_content_textarea"
                placeholder="Start writing private notepad content here..."
                value={editorContent}
                onChange={(e) => setEditorContent(e.target.value)}
                className={`w-full min-h-[250px] bg-transparent outline-none resize-none mt-4 text-sm ${
                  editorColor !== 0xFFFFFFFF ? 'text-slate-800 placeholder:text-slate-550' : 'text-slate-800 dark:text-slate-200 placeholder:text-slate-500'
                }`}
                style={{
                  lineHeight: '28px',
                  backgroundImage: `repeating-linear-gradient(transparent, transparent 27px, ${
                    editorColor !== 0xFFFFFFFF 
                      ? 'rgba(15, 23, 42, 0.12)' 
                      : (darkMode ? 'rgba(226, 232, 240, 0.12)' : 'rgba(15, 23, 42, 0.08)')
                  } 27px, ${
                    editorColor !== 0xFFFFFFFF 
                      ? 'rgba(15, 23, 42, 0.12)' 
                      : (darkMode ? 'rgba(226, 232, 240, 0.12)' : 'rgba(15, 23, 42, 0.08)')
                  } 28px)`,
                  backgroundAttachment: 'local',
                  backgroundSize: '100% 28px',
                  paddingTop: '4px',
                }}
              />

              {/* Color swatch selection swatches */}
              <div className="mt-6">
                <span className={`text-[10px] font-bold uppercase tracking-wider ${
                  editorColor !== 0xFFFFFFFF ? 'text-slate-600' : 'text-slate-400'
                }`}>
                  Select Note Color Accent
                </span>
                <div className="flex gap-2.5 mt-2 overflow-x-auto pb-1 scrollbar-none">
                  {NOTE_COLORS.map((c) => (
                    <button
                      key={c.value}
                      id={`editor_color_${c.value === 0xFFFFFFFF ? 'default' : c.hex}`}
                      onClick={() => setEditorColor(c.value)}
                      className="w-8 h-8 rounded-full border flex items-center justify-center shrink-0"
                      style={{ 
                        backgroundColor: c.hex, 
                        borderColor: editorColor === c.value ? '#000000' : '#e2e8f0' 
                      }}
                    >
                      {editorColor === c.value && <Check className="w-4 h-4 text-slate-800" />}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Editor Bottom Stats footer */}
            <div className="flex items-center justify-between text-xs text-slate-400 px-1">
              <span>Words: {wordCount}  |  Characters: {charCount}</span>
              <span className="font-semibold text-blue-500">{syncStatus}</span>
            </div>
          </div>
        )}

        {/* VIEW 3: SETTINGS CONTROL PANEL */}
        {currentView === 'settings' && (
          <div className="flex flex-col gap-6 animate-fade-in">
            <h3 className="font-bold text-lg">System Settings</h3>

            <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl divide-y divide-slate-100 dark:divide-slate-800">
              
              <div className="p-4 flex items-center justify-between">
                <div>
                  <h4 className="font-semibold text-sm">Dark Theme Selection</h4>
                  <p className="text-xs text-slate-400">Toggle dark workspace backdrop color</p>
                </div>
                <button
                  id="settings_dark_switch"
                  onClick={() => setDarkMode(!darkMode)}
                  className={`w-11 h-6 rounded-full transition-colors relative flex items-center p-1 cursor-pointer ${darkMode ? 'bg-blue-600' : 'bg-slate-300'}`}
                >
                  <div className={`w-4 h-4 bg-white rounded-full shadow-md transition-all ${darkMode ? 'translate-x-5' : 'translate-x-0'}`} />
                </button>
              </div>

              <div className="p-4 flex items-center justify-between">
                <div>
                  <h4 className="font-semibold text-sm">Security passcode lock</h4>
                  <p className="text-xs text-slate-400">
                    {securityPin ? 'A 4-digit security PIN is active' : 'Secure database using lock-PIN screen'}
                  </p>
                </div>
                <div>
                  {securityPin ? (
                    <button
                      id="settings_remove_pin_btn"
                      onClick={() => {
                        setSecurityPin(null);
                        alert('Passcode protection deactivated successfully.');
                      }}
                      className="text-xs font-semibold text-red-500 hover:underline"
                    >
                      Remove PIN
                    </button>
                  ) : (
                    <button
                      id="settings_enable_pin_btn"
                      onClick={() => {
                        setIsSettingPin(true);
                        setIsLocked(true);
                        setPinEntry('');
                        setTempNewPin(null);
                        setLockScreenStatus('Create a 4-Digit Passcode');
                      }}
                      className="px-3.5 py-1.5 text-xs font-semibold bg-blue-50 dark:bg-blue-950/30 text-blue-600 dark:text-blue-400 rounded-xl hover:bg-blue-100"
                    >
                      Enable PIN
                    </button>
                  )}
                </div>
              </div>

              {securityPin && (
                <div className="p-4 flex items-center justify-between">
                  <div>
                    <h4 className="font-semibold text-sm">Mock Biometrics</h4>
                    <p className="text-xs text-slate-400">Lock contains biometric face ID integrations</p>
                  </div>
                  <Check className="w-5 h-5 text-emerald-500" />
                </div>
              )}

              <div className="p-4 flex items-center justify-between">
                <div>
                  <h4 className="font-semibold text-sm">Manage Custom Filters</h4>
                  <p className="text-xs text-slate-400">Edit notes group catalog structure</p>
                </div>
                <button
                  id="settings_nav_cats"
                  onClick={() => setCurrentView('categories')}
                  className="p-1 px-3 bg-slate-50 dark:bg-slate-800 text-slate-500 hover:bg-slate-100 rounded-lg text-xs font-semibold flex items-center"
                >
                  Configure
                  <ChevronRight className="w-3.5 h-3.5" />
                </button>
              </div>

              <div className="p-4 flex items-center justify-between">
                <div>
                  <h4 className="font-semibold text-sm">Migration Backups</h4>
                  <p className="text-xs text-slate-400">Export ZIP or Paste notepad JSON configs</p>
                </div>
                <button
                  id="settings_nav_backup"
                  onClick={() => setCurrentView('migration')}
                  className="p-1 px-3 bg-slate-50 dark:bg-slate-800 text-slate-500 hover:bg-slate-100 rounded-lg text-xs font-semibold flex items-center"
                >
                  Backup
                  <ChevronRight className="w-3.5 h-3.5" />
                </button>
              </div>

            </div>

            {/* About Info Card */}
            <div className="p-5 bg-blue-50/40 dark:bg-blue-950/10 border border-blue-100/40 dark:border-blue-950/20 rounded-3xl text-center">
              <Info className="w-6 h-6 text-blue-500 mx-auto mb-2" />
              <h5 className="font-bold text-xs">Offline Native Core App</h5>
              <p className="text-[11px] text-slate-400 mt-1 max-w-sm mx-auto">
                All notes and configurations are held entirely within this storage sandboxed browser environment, built alongside production-ready Flutter structures.
              </p>
            </div>
          </div>
        )}

        {/* VIEW 4: CATEGORY MANAGER PANEL */}
        {currentView === 'categories' && (
          <div className="flex flex-col gap-4 animate-fade-in">
            <div className="flex items-center justify-between">
              <button
                id="cats_back_btn"
                onClick={() => setCurrentView('settings')}
                className="flex items-center gap-1 text-xs font-semibold text-blue-500"
              >
                <ArrowLeft className="w-4 h-4" />
                <span>Back to Settings</span>
              </button>
              <h3 className="font-bold text-sm">Manage Filters</h3>
            </div>

            {/* Inline add component */}
            <div className="flex gap-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 p-2.5 rounded-2xl shadow-xs">
              <input
                id="cats_new_text_input"
                type="text"
                placeholder="New CategoryName (e.g. Finance)"
                value={tempCategoryInput}
                onChange={(e) => setTempCategoryInput(e.target.value)}
                className="flex-1 px-3 py-1.5 outline-none bg-transparent text-sm"
              />
              <button
                id="cats_add_save_btn"
                onClick={addCustomCategory}
                className="px-4 py-1.5 text-xs font-semibold bg-blue-600 text-white rounded-xl hover:bg-blue-700 active:scale-95 transition"
              >
                Add Category
              </button>
            </div>

            {/* Existing custom category rows */}
            <div className="flex flex-col gap-2.5 mt-2">
              {categories.map((cat) => {
                const count = notes.filter(n => n.categoryName === cat).length;
                const isProtected = DEFAULT_CATEGORIES.some(c => c.toLowerCase() === cat.toLowerCase());
                return (
                  <div
                    key={cat}
                    id={`cat_manager_row_${cat.toLowerCase()}`}
                    className="flex items-center justify-between p-4 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl"
                  >
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-blue-50 dark:bg-blue-950/20 text-blue-600 dark:text-blue-400 rounded-xl">
                        <Folder className="w-4 h-4" />
                      </div>
                      <div>
                        <h4 className="font-bold text-sm">{cat}</h4>
                        <span className="text-[10px] text-slate-400">{count} notes active</span>
                      </div>
                    </div>

                    {isProtected ? (
                      <span className="text-[10px] font-bold uppercase text-slate-400 tracking-wider">System Locked</span>
                    ) : (
                      <button
                        id={`cat_del_btn_${cat.toLowerCase()}`}
                        onClick={() => removeCategory(cat)}
                        className="p-1 px-2 text-[10px] font-semibold text-red-500 hover:bg-red-50 dark:hover:bg-red-950/25 rounded-lg border border-red-200 dark:border-none"
                      >
                        Delete
                      </button>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* VIEW 5: DATA EXPORT MIGRATION SCREEN */}
        {currentView === 'migration' && (
          <div className="flex flex-col gap-6 animate-fade-in">
            <div className="flex items-center justify-between">
              <button
                id="migration_back_btn"
                onClick={() => setCurrentView('settings')}
                className="flex items-center gap-1 text-xs font-semibold text-blue-500"
              >
                <ArrowLeft className="w-4 h-4" />
                <span>Back to Settings</span>
              </button>
              <h3 className="font-bold text-sm">Backup & Restoration</h3>
            </div>

            {/* Overview statistics info card */}
            <div className="p-5 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-3xl text-center">
              <RefreshCw className="w-8 h-8 text-slate-400 mx-auto mb-3" />
              <h4 className="font-bold text-sm mb-1 text-slate-800 dark:text-slate-100">Database Block Profile</h4>
              
              <div className="grid grid-cols-3 gap-2 mt-4 text-center">
                <div className="p-3 bg-slate-50 dark:bg-slate-850 rounded-2xl">
                  <span className="block text-lg font-bold">{notes.length}</span>
                  <span className="text-[10px] text-slate-400">Total Notes</span>
                </div>
                <div className="p-3 bg-slate-50 dark:bg-slate-850 rounded-2xl">
                  <span className="block text-lg font-bold">{notes.filter(n => n.isPinned).length}</span>
                  <span className="text-[10px] text-slate-400">Pinned</span>
                </div>
                <div className="p-3 bg-slate-50 dark:bg-slate-850 rounded-2xl">
                  <span className="block text-lg font-bold">{categories.length}</span>
                  <span className="text-[10px] text-slate-400">Filters</span>
                </div>
              </div>
            </div>

            {/* Export block code */}
            <div>
              <span className="block text-[11px] font-bold text-slate-400 uppercase tracking-wider mb-2">Export Backup JSON Block</span>
              <textarea
                id="export_output_textarea"
                readOnly
                value={JSON.stringify({ app: 'SmartNotes', version: 1, categories, notes }, null, 2)}
                onClick={(e) => {
                  (e.target as HTMLTextAreaElement).select();
                }}
                className="w-full h-32 p-3 text-xs bg-slate-100 dark:bg-slate-950 border border-slate-200 dark:border-slate-850 text-slate-500 font-mono rounded-2xl select-all placeholder:text-slate-500 outline-none"
              />
              <button
                id="copy_backup_btn"
                onClick={() => {
                  const dataStr = JSON.stringify({ app: 'SmartNotes', version: 1, categories, notes });
                  navigator.clipboard.writeText(dataStr);
                  alert('Backup payload copied to Clipboard! Copy this text back to restore notes elsewhere.');
                }}
                className="w-full mt-2.5 py-3 text-xs font-bold bg-blue-600 text-white rounded-2xl hover:bg-blue-700 active:scale-98 transition duration-150"
              >
                Copy Backup Block to Clipboard
              </button>
            </div>

            {/* Restore block input */}
            <div className="border-t border-slate-200 dark:border-slate-800 pt-6">
              <span className="block text-[11px] font-bold text-slate-400 uppercase tracking-wider mb-2">Restore Backup JSON Block</span>
              <textarea
                id="restore_input_textarea"
                placeholder="Paste JSON block here to overwrite and load all notes..."
                value={jsonInput}
                onChange={(e) => setJsonInput(e.target.value)}
                className="w-full h-24 p-3 text-xs bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-850 text-slate-800 dark:text-slate-100 font-mono rounded-2xl placeholder:text-slate-400 outline-none focus:ring-2 focus:ring-blue-500"
              />
              
              <div className="flex gap-2.5 mt-2.5">
                <button
                  id="restore_data_btn"
                  onClick={handleImportJson}
                  className="flex-1 py-3 text-xs font-bold bg-slate-200 dark:bg-slate-800 hover:bg-slate-300 dark:hover:bg-slate-700 rounded-2xl transition"
                >
                  Import JSON block
                </button>
                <button
                  id="load_demo_seeds_btn"
                  onClick={loadSampleDemoData}
                  className="px-4 py-3 text-xs font-bold border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-2xl transition"
                >
                  Demo Seeds
                </button>
              </div>
            </div>

          </div>
        )}

      </main>

      {/* --- FLOATING ACTION TRIGGER BAR --- */}
      {currentView === 'list' && (
        <button
          id="floating_add_note_btn"
          onClick={startNewNote}
          className="fixed bottom-20 right-6 p-4 rounded-2xl bg-blue-600 text-white shadow-lg hover:bg-blue-700 active:scale-95 transition-all duration-150 flex items-center justify-center"
          title="Create New Note"
        >
          <Plus className="w-6 h-6" />
        </button>
      )}

      {/* --- NAV APP TAB CORE BOTTOM NAVIGATION BAR --- */}
      <nav className="fixed bottom-0 left-0 right-0 z-40 bg-white dark:bg-slate-900 border-t border-slate-200 dark:border-slate-800 flex items-center justify-around py-2.5">
        <button
          id="nav_item_notes"
          onClick={() => {
            if (currentView === 'editor') saveActiveNote();
            setCurrentView('list');
          }}
          className={`flex flex-col items-center gap-1 focus:outline-none ${currentView === 'list' ? 'text-blue-600' : 'text-slate-400'}`}
        >
          <FileText className="w-5 h-5" />
          <span className="text-[10px] font-semibold">Notepad</span>
        </button>
        <button
          id="nav_item_settings"
          onClick={() => {
            if (currentView === 'editor') saveActiveNote();
            setCurrentView('settings');
          }}
          className={`flex flex-col items-center gap-1 focus:outline-none ${currentView === 'settings' ? 'text-blue-600' : 'text-slate-400'}`}
        >
          <Settings className="w-5 h-5" />
          <span className="text-[10px] font-semibold">Settings</span>
        </button>
      </nav>

    </div>
  );
}
