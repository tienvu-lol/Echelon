import { StyleSheet, View, Text, Pressable } from 'react-native';
import { useState, useEffect } from 'react';
import { healthCheck } from '../../services/api';

export default function DiscoverScreen() {
  const [backendStatus, setBackendStatus] = useState<string>('checking...');

  useEffect(() => {
    healthCheck()
      .then((res) => setBackendStatus(`Backend: ${res.status}`))
      .catch((err) => setBackendStatus(`Backend: offline (${err.message})`))
  }, []);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Discover</Text>
      <Text style={styles.subtitle}>Swipe on opportunities</Text>
      
      <View style={styles.cardPlaceholder}>
        <Text style={styles.cardText}>Opportunity cards will appear here</Text>
        <Text style={styles.cardSubtext}>Swipe right to save, left to skip</Text>
      </View>

      <View style={styles.statusBar}>
        <Text style={styles.statusText}>{backendStatus}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
    backgroundColor: '#f5f5f5',
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    marginBottom: 8,
    color: '#333',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    marginBottom: 32,
  },
  cardPlaceholder: {
    width: '100%',
    height: 400,
    backgroundColor: '#fff',
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 3,
    padding: 20,
  },
  cardText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#999',
    textAlign: 'center',
  },
  cardSubtext: {
    fontSize: 14,
    color: '#bbb',
    marginTop: 8,
    textAlign: 'center',
  },
  statusBar: {
    marginTop: 24,
    padding: 12,
    backgroundColor: '#e8e8e8',
    borderRadius: 8,
  },
  statusText: {
    fontSize: 12,
    color: '#666',
    fontFamily: 'monospace',
  },
});
