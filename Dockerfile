FROM debian:bookworm-slim AS flutter-build
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils zip \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch 3.47.4 https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter precache --web
WORKDIR /src/flutter
COPY rental_equipment_app/pubspec.yaml rental_equipment_app/pubspec.lock ./
RUN flutter pub get --enforce-lockfile
COPY rental_equipment_app/ ./
RUN printf 'API_URL=\n' > .env \
    && flutter build web --no-pub --dart-define=API_USE_SAME_ORIGIN=true

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS api-build
WORKDIR /src
COPY WebApi/WebApi.csproj WebApi/
RUN dotnet restore WebApi/WebApi.csproj
COPY WebApi/ WebApi/
RUN dotnet publish WebApi/WebApi.csproj -c Release --no-restore -o /out

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
ENV ASPNETCORE_HTTP_PORTS=10000
EXPOSE 10000
COPY --chown=app:app --from=api-build /out/ ./
COPY --chown=app:app --from=flutter-build /src/flutter/build/web/ ./wwwroot/
USER app
ENTRYPOINT ["dotnet", "WebApi.dll"]
