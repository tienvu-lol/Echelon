import { StyleSheet, View, Text, FlatList } from 'react-native';

export default function SavedScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Saved</Text>
      <Text style={styles.subtitle}>Your saved opportunities</Text>
      
      <View style={styles.emptyState}>
        <Text style={styles.emptyIcon}>📌</Text>
        <Text style={styles.emptyText}>No saved opportunities yet</Text>
        <Text style={styles.emptySubtext}>
          Swipe right on opportunities in Discover to save them here
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
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
    marginBottom: 24,
  },
  emptyState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  emptyIcon: {
    fontSize: 48,
    marginBottom: 16,
  },
  emptyText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#999',
    marginBottom: 8,
  },
  emptySubtext: {
    fontSize: 14,
    color: '#bbb',
    textAlign: 'center',
    paddingHorizontal: 40,
  },
});
