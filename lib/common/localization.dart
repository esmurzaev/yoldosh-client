abstract class Localizations {
  String yes;
  String no;
  String version;
  String language;
  String okButtonLabel;
  String cancelButtonLabel;
  String cancelTrip;
  String lightTheme;
  String darkTheme;
  String delete;
  String deleteFromFavorite;
  String info;
  String km;
  String searchFieldLabel;
  String enterName;
  String nameIsShort;
  String start;
  String seat;
  String sum;
  String tariff;
  String noConn;
  String noLocation;
  String locationDet;
  String outOfArea;
  String clientLocationWeak;
  String driverLocationWeak;
  String noService;
  String connToServer;
  String routeErr;
  String connError;
  String noRoad;
  String driverMode;
  String timeStampErr;
  String isOldApp;
  String carWait;
  String carFound;
  String driverCanceled;
  String selectCarDescr;
  String carBrand;
  String carColor;
  String clientSearch;
  String clientFound;
  String clientCanceled;
  String clientSearchEnd;
  // String carOptionsDialog;
  String description;
  List<String> colors;
  List<String> districts;

  static Localizations load(String languageCode) {
    switch (languageCode) {
      case "ru":
        return LocalizationsRu();
        break;
      case "uz":
        return LocalizationsUz();
        break;
      // case "oz":
      // return LocalizationsOz();
      // break;
      default:
        return LocalizationsEn();
    }
  }
}

class LocalizationsEn extends Localizations {
  final String yes = "YES";
  final String no = "NO";
  final String version = "version";
  final String language = "Language";
  final String okButtonLabel = "OK";
  final String cancelButtonLabel = "CANCEL";
  final String cancelTrip = "Cancel the trip?";
  final String lightTheme = "Light theme";
  final String darkTheme = "Dark theme";
  final String delete = "DELETE";
  final String deleteFromFavorite = "Delete from favorite?";
  final String info = "Info";
  final String km = "km";
  final String searchFieldLabel = "Search destination";
  final String enterName = "Enter your name";
  final String nameIsShort = "Name must not be shorter than 3 letters";
  final String start = "START";
  final String seat = "Seat";
  final String sum = "sum";
  final String tariff = "Tariff";
  final String noConn = "No internet connection";
  final String noLocation = "Location not enabled,\nor GPS signal not found";
  final String locationDet = "Location determination...";
  final String outOfArea = "Your location is outside the service area"; // Region is not supported / Your place is outside the service area
  final String clientLocationWeak = "GPS signal is weak,\ntry go out to open terrain";
  final String driverLocationWeak = "GPS signal is weak";
  final String noService = "Sorry, server is not responding";
  final String connToServer = "Connection to server...";
  final String routeErr = "Sorry couldn't build a route";
  final String connError = "Connection error...";
  final String noRoad = "No road found nearby";
  final String driverMode = "Driver mode";
  final String timeStampErr = "Phone time not correct";
  final String isOldApp = "Please update this app";
  final String carWait = "Waiting for a companion...";
  final String carFound = "Companion found!";
  final String driverCanceled = "Driver canceled the trip";
  final String selectCarDescr = "Select car description";
  final String carBrand = "Car brand";
  final String carColor = "Car color";
  final String clientSearch = "Search for passengers...";
  final String clientFound = "Passenger found!";
  final String clientCanceled = "Passenger canceled the trip";
  final String clientSearchEnd = "Search for passengers is finished";
  // final String carOptionsDialog = "To switch to driver mode, first select vehicle descriptions";
  final String description =
      "Being near the road or stop, select a destination from the list.\n\n" + // or find by search\n\n" +
          "Make a request specifying the number of seats and the fare.\n\n" +
          "Wait for the companion.\n\n" +
          "When a companion appears on the road, the application will notify you.\n\n" +
          "Have a good trip!";
  final List<String> colors = [
    "White",
    "Beige",
    "Yellow",
    "Orange",
    "Brown",
    "Red",
    "Burgundy",
    "Silver",
    "Gray",
    "Dark grey",
    "Black",
    "Blue",
    "Dark blue",
    "Green",
    "Gently green",
  ];
  final List<String> districts = [
    "",
    "Almazar district. Tashkent",
    "Bektemir district. Tashkent",
    "Chilanzar district. Tashkent",
    "Mirabad district. Tashkent",
    "Mirzo Ulugbek district. Tashkent",
    "Sergeli district. Tashkent",
    "Shaykhontokhur district. Tashkent",
    "Uchtepa district. Tashkent",
    "Yakkasaray district. Tashkent",
    "Yashnabad district. Tashkent",
    "Yunusabad district. Tashkent",
    "Ahangaran district. Tashkent region",
    "Akkurgan district. Tashkent region",
    "Bekabad district. Tashkent region",
    "Bostanlik district. Tashkent region",
    "Buka district. Tashkent region",
    "Chinaz district. Tashkent region",
    "Chirchik city. Tashkent region",
    "Kibray district. Tashkent region",
    "Kuyichirchik district. Tashkent region",
    "Parkent district. Tashkent region",
    "Pskent district. Tashkent region",
    "Tashkent district. Tashkent region",
    "Urtachirchik district. Tashkent region",
    "Yangiyul district. Tashkent region",
    "Yukarichirchik district. Tashkent region",
    "Zangiata district. Tashkent region",
  ];
}

class LocalizationsRu extends Localizations {
  final String yes = "ДА";
  final String no = "НЕТ";
  final String version = "версия";
  final String language = "Язык";
  final String okButtonLabel = "ОК";
  final String cancelButtonLabel = "ОТМЕНА";
  final String cancelTrip = "Отменить поездку?";
  final String lightTheme = "Светлая тема";
  final String darkTheme = "Темная тема";
  final String delete = "УДАЛИТЬ";
  final String deleteFromFavorite = "Удалить из избранного?";
  final String info = "Инфо";
  final String km = "км";
  final String searchFieldLabel = "Поиск пункта назначения";
  final String enterName = "Введите свое имя";
  final String nameIsShort = "Имя не должно быть короче 3 букв";
  final String start = "СТАРТ";
  final String seat = "Место";
  final String sum = "сум";
  final String tariff = "Тариф";
  final String noConn = "Подключение к Интернету отсутствует";
  final String noLocation = "Геолокация не включено,\nили GPS-сигнал не найдено";
  final String locationDet = "Определение местоположения...";
  final String outOfArea =
      "Ваше местоположение находится за пределами зоны обслуживания"; // Регион не поддерживается / Ваша местоположение вне зоны обслуживания сервиса
  final String clientLocationWeak = "GPS-сигнал слабый,\nпопробуйте выйти на открытую местность";
  final String driverLocationWeak = "GPS-сигнал слабый";
  final String noService = "Извините, сервер не отвечает";
  final String connToServer = "Подключение к серверу...";
  final String routeErr = "Извините, не удалось построить маршрут";
  final String connError = "Ошибка соединения..."; // подключения соединения
  final String noRoad = "Поблизости дорога не найдено";
  final String driverMode = "Режим водителя";
  final String timeStampErr = "Время телефона не корректно";
  final String isOldApp = "Пожалуюста, обновитье приложению";
  final String carWait = "Ожидание попутчика...";
  final String carFound = "Попутчик найден!";
  final String driverCanceled = "Водитель отменил поездку";
  final String selectCarDescr = "Выберите описание автомобиля";
  final String carBrand = "Брэнд автомобиля";
  final String carColor = "Цвет автомобиля";
  final String clientSearch = "Поиск пассажиров...";
  final String clientFound = "Найден пассажир!";
  final String clientCanceled = "Пассажир отменил поездку";
  final String clientSearchEnd = "Поиск пассажиров закончен";
  // final String carOptionsDialog = "Чтобы переключиться в режим водителя, сначала выберите описание автомобиля";
  final String description =
      "Находясь рядом с дорогой или остановкой, выберите пункт назначения из списка.\n\n" + // или найдите по поиску\n\n" + // место отправления —
          "Сделайте запрос указав количество мест и тарифа.\n\n" +
          "Ждитье попутчика.\n\n" +
          "При появлений попутчика на дороге, приложения оповестить вас.\n\n" +
          "Счастливого пути!";
  final List<String> colors = [
    "Белый",
    "Бежевый",
    "Желтый",
    "Оранжевый",
    "Коричневый",
    "Красный",
    "Бордовый",
    "Серебристый",
    "Серый",
    "Тёмно серый",
    "Чёрный",
    "Синий",
    "Тёмно синий",
    "Зелёный",
    "Нежно зелёный",
  ];
  final List<String> districts = [
    "",
    "Алмазарский район. Ташкент",
    "Бектемирский район. Ташкент",
    "Чиланзарский район. Ташкент",
    "Мирабадский район. Ташкент",
    "Мирзо-Улугбекский район. Ташкент",
    "Сергелийский район. Ташкент",
    "Шайхантахурский район. Ташкент",
    "Учтепинский район. Ташкент",
    "Яккасарайский район. Ташкент",
    "Яшнабадский район. Ташкент",
    "Юнусабадский район. Ташкент",
    "Ахангаранский район. Ташкентская область",
    "Аккурганский район. Ташкентская область",
    "Бекабадский район. Ташкентская область",
    "Бостанлыкский район. Ташкентская область",
    "Букинский район. Ташкентская область",
    "Чиназский район. Ташкентская область",
    "Чирчик. Ташкентская область",
    "Кибрайский район. Ташкентская область",
    "Куйичирчикский район. Ташкентская область",
    "Паркентский район. Ташкентская область",
    "Пскентский район. Ташкентская область",
    "Ташкентский район. Ташкентская область",
    "Уртачирчикский район. Ташкентская область",
    "Янгиюльский район. Ташкентская область",
    "Юкоричирчикский район. Ташкентская область",
    "Зангиатинский район. Ташкентская область",
  ];
}

class LocalizationsUz extends Localizations {
  final String yes = "HA";
  final String no = "YO'Q";
  final String version = "versiya";
  final String language = "Til";
  final String okButtonLabel = "OK";
  final String cancelButtonLabel = "BEKOR QILISH";
  final String cancelTrip = "Safarni bekor qilish?";
  final String lightTheme = "Oq tema";
  final String darkTheme = "Qora tema";
  final String delete = "O'CHIRISH";
  final String deleteFromFavorite = "Tanlanganlardan o'chirish?";
  final String info = "Info";
  final String km = "km";
  final String searchFieldLabel = "Belgilangan manzilni qidirish";
  final String enterName = "Ismingizni kiriting";
  final String nameIsShort = "Ism 3 harfdan kam bo'lmasligi kerak";
  final String start = "BOSHLASH";
  final String seat = "Joy";
  final String sum = "sum";
  final String tariff = "Tarif";
  final String noConn = "Internetga ulanish y'oq";
  final String noLocation = "Geolokatsiya yoqilmagan,\nyoki GPS signal topilmadi";
  final String locationDet = "Joylashuvni aniqlash...";
  final String outOfArea = "Sizning joyingiz hizmat ko'rsatish hududidan tashqarida"; // doirasidan
  final String clientLocationWeak = "GPS signal kuchsiz,\nochiq joyga chiqishga harakat qiling";
  final String driverLocationWeak = "GPS signal kuchsiz";
  final String noService = "Kechirasiz, server javob bermayapti";
  final String connToServer = "Serverga ulanish...";
  final String routeErr = "Kechirasiz, marshrutni tuzib bo'lmadi";
  final String connError = "Serverga ulanishda xatolik...";
  final String noRoad = "Yaqin atrofda hech qanday yo'l topilmadi";
  final String driverMode = "Haydovchi rejimi";
  final String timeStampErr = "Telefon vaqti noto'g'ri";
  final String isOldApp = "Iltimos, ilovani yangilang";
  final String carWait = "Hamrohni kutish...";
  final String carFound = "Hamroh topildi!";
  final String driverCanceled = "Haydovchi safarni bekor qildi";
  final String selectCarDescr = "Avtomobil tavsifini tanlang";
  final String carBrand = "Avtomobil brendi";
  final String carColor = "Avtomobil rangi";
  final String clientSearch = "Yo'lovchilarni qidirish...";
  final String clientFound = "Yo'lovchi topildi!";
  final String clientCanceled = "Yo'lovchi safarni bekor qildi";
  final String clientSearchEnd = "Yo'lovchilarni qidirish tugallandi";
  // final String carOptionsDialog = "Haydovchi rejimiga o'tish uchun avval avtomobil tavsifini tanlang";
  final String description =
      "Yo'l yoki bekat yonida bo'lgan holda, belgilangan manzilni tanlang.\n\n" + // yoki qidiruv orqali toping\n\n" +
          "Yo'lovchilar sonini va tarifni ko'rsatgan holda so'rov yuboring.\n\n" +
          "Hamrohni kuting.\n\n" +
          "Yo'lda hamroh paydo bo'lganida, ilova sizni habardor qiladi.\n\n" +
          "Oq yo'l!";
  final List<String> colors = [
    "Oq",
    "Bej",
    "Sariq",
    "To'q sariq",
    "Jigarrang",
    "Qizil",
    "To'q qizil",
    "Kumushrang",
    "Kulrang",
    "To'q kulrang",
    "Qora",
    "Moviy",
    "To'q ko'k",
    "Yashil",
    "Och yashil",
  ];
  final List<String> districts = [
    "",
    "Olmazor tumani. Toshkent",
    "Bektemir tumani. Toshkent",
    "Chilonzor tumani. Toshkent",
    "Mirobod tumani. Toshkent",
    "Mirzo Ulug'bek tumani. Toshkent",
    "Sergeli tumani. Toshkent",
    "Shayxontohur tumani. Toshkent",
    "Uchtepa tumani. Toshkent",
    "Yakkasaroy tumani. Toshkent",
    "Yashnobod tumani. Toshkent",
    "Yunusobod tumani. Toshkent",
    "Ohangaron tumani. Toshkent viloyati",
    "Oqqo'rg'on tumani. Toshkent viloyati",
    "Bekobod tumani. Toshkent viloyati",
    "Bo'stonliq tumani. Toshkent viloyati",
    "Bo'ka tumani. Toshkent viloyati",
    "Chinoz tumani. Toshkent viloyati",
    "Chirchiq. Toshkent viloyati",
    "Qibray tumani. Toshkent viloyati",
    "Quyichirchiq tumani. Toshkent viloyati",
    "Parkent tumani. Toshkent viloyati",
    "Piskent tumani. Toshkent viloyati",
    "Toshkent tumani. Toshkent viloyati",
    "O'rtachirchiq tumani. Toshkent viloyati",
    "Yangiyo'l tumani. Toshkent viloyati",
    "Yuqorichirchiq tumani. Toshkent viloyati",
    "Zangiota tumani. Toshkent viloyati",
  ];
}
/*
class LocalizationsOz extends Localizations {
  final String yes = "ХА";
  final String no = "ЙЎҚ";
  final String version = "версия";
  final String language = "Тил";
  final String cancelButtonLabel = "БЕКОР ҚИЛИШ";
  final String cancelTrip = "Сафарни бекор қилиш?";
  final String lightTheme = "Оқ тема";
  final String darkTheme = "Қора тема";
  final String delete = "ЎЧИРИШ";
  final String deleteFromFavorite = "Танланганлардан ўчириш?";
  final String info = "Инфо";
  final String km = "км";
  final String searchFieldLabel = "Белгиланган манзилни қидириш";
  final String enterName = "Исмингизни киритинг";
  final String nameIsShort = "Исм 3 харфдан кам бўлмаслиги керак";
  final String start = "БОШЛАШ";
  final String seat = "Жой";
  final String sum = "сўм";
  final String tariff = "Тариф";
  final String noConn = "Интернетга уланиш йўқ";
  final String noLocation = "Геолокация йоқилмаган,\nёки GPS сигнал топилмади";
  final String locationDet = "Жойлашувни аниқлаш...";
  final String clientLocationWeak = "GPS сигнал кучсиз,\nочиқ жойга чиқишга харакат қилинг";
  final String driverLocationWeak = "GPS сигнал кучсиз";
  final String noService = "Кечирасиз, сервер жавоб бермаяпти";
  final String connToServer = "Серверга уланиш...";
  final String routeErr = "Кечирасиз, маршрутни тузиб бўлмади";
  final String connError = "Серверга уланишда хатолик...";
  final String noRoad = "Яқин атрофда хеч қандай йўл топилмади";
  final String driverMode = "Хайдовчи режими";
  final String timeStampErr = "Телефон вақти нотўғри";
  final String isOldApp = "Илтимос, иловани янгиланг";
  final String carWait = "Хамрохни кутиш...";
  final String carFound = "Хамрох топилди!";
  final String driverCanceled = "Хайдовчи сафарни бекор қилди";
  final String selectCarDescr = "Автомобил тавсифини танланг";
  final String carBrand = "Автомобил  брэнди";
  final String carColor = "Автомобил ранги";
  final String clientSearch = "Йўловчиларни қидириш...";
  final String clientFound = "Йўловчи топилди!";
  final String clientCanceled = "Йўловчи сафарни бекор қилди";
  final String clientSearchEnd = "Йўловчиларни қидириш тугалланди";
  // final String carOptionsDialog = "Хайдовчи режимига ўтиш учун аввал автомобил тавсифини танланг";
  final String description = "Йўл ёки бекат ёнида бўлган холда,\nбелгиланган манзилни танланг\n\n" + // ёки қидирув орқали топинг\n\n" +
      "Ёловчилар сонини ва тарифни кўрсатган холда сўров юборинг\n\n" +
      "Хамрохни кутинг\n\n" +
      "Йўлда хамрох пайдо булганида, илова сизни хабардор қилади\n\n" +
      "Оқ йўл!";
  final List<String> colors = [
    "Оқ",
    "Беж",
    "Сариқ",
    "Тўқ сариқ",
    "Жигарранг",
    "Қизил",
    "Тўқ қизил",
    "Кумушранг",
    "Кулранг",
    "Тўқ кулранг",
    "Қора",
    "Мовий",
    "Тўқ кўк",
    "Яшил",
    "Оч яшил",
  ];
  final List<String> districts = [
  ""
  ];
}
*/
