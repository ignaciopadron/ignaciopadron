#!/bin/bash

# -z: Verifica si la variable está vacía Es una prueba de longitud cero: -z significa "string está vacío".
# Entonces, -z "$1" da true si $1 es "" (vacío).
# [ -z "$1" ] evalúa: "¿Está vacío $1?"
# Si la condición del test da true, entonces ejecuta el bloque que sigue.

#Verifica si se pasó un mensaje de commit
if [ -z "$1" ]; then
    echo "⚠️  pon el mensaje de commit furro!"
    echo "Uso: ./git-auto.sh \"tu mensaje de commit\""
    echo "❌ Abortando commit debido a que el mensaje está en blanco."
    exit 1
fi


echo "📦 Haciendo commit..."
git add .

git commit -m "$1"
echo "🚀 Pusheando a origin/main..."
git push origin main


if [ $? -ne 0 ]; then
    echo "⚠️  Algo salió mal furro!"
    exit 1
fi
echo "✅  Commit y push realizados con éxito titoo!"